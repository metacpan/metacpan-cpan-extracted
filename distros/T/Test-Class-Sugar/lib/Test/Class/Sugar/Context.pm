package Test::Class::Sugar::Context;
our $VERSION = '0.0300';
use base qw/Devel::Declare::Context::Simple/;


use Carp qw/croak/;

sub strip_test_desc_string {
    my $self = shift;
    $self->skipspace;

    return unless $self->looking_at(q{'});

    my $linestr = $self->get_linestr();
    my $length = Devel::Declare::toke_scan_str($self->offset);
    my $desc = Devel::Declare::get_lex_stuff();
    Devel::Declare::clear_lex_stuff();
    if ( $length < 0 ) {
        $linestr .= $self->get_linestr();
        $length = rindex($linestr, q{'}) - $self->offset + 1;
    }
    else {
        $linestr = $self->get_linestr();
    }

    substr($linestr, $self->offset, $length) = '';
    $self->set_linestr($linestr);

    $desc =~ s/^\s+|\s$//g;
    $desc =~ s/\s+/_/g;
    $desc =~ s/\W+//g;
    $desc =~ s/^(\d)/_$1/;

    return $desc
}

sub strip_names {
    my $self = shift;

    $self->skipspace;
    my $declarator = $self->declarator;
    my $name = $declarator;

    unless($self->looking_at('>>')) {
        while (! $self->looking_at(qr/(?:{|>>)/,1) ) {
            $self->looking_at(qr{\w}) or croak("I don't understand ", $self->peek_next_char);
            $name .= ('_' . $self->strip_name);
            croak "Expecting a simple name; try quoting it" unless defined $name;
            $self->skipspace;
        }
    }
    return if $name eq 'test';
    if ($name eq $declarator) {
        $name .= $self->get_curstash_name;
        $name =~ s/::/_/g;
    }
    return $name;
}

sub strip_test_name {
    my $self = shift;
    $self->skipspace;

    my $name = $self->strip_test_desc_string
    || $self->strip_names
    || return;

    return lc($name)
}

sub looking_at {
    my($self, $expected, $len) = @_;
    unless (defined $len) {
        $len = ref($expected) ? undef : length($expected);
    }

    $expected = quotemeta($expected) unless ref($expected);

    my $buffer = $self->get_buffer;
    while ($len && $len > length($buffer)) {
        $buffer = $self->extend_buffer;
    }

    $buffer =~ /^$expected/;
}

sub peek_next_char {
    my $self = shift;
    my $buffer = $self->get_buffer;
    return substr($buffer, 0, 1);
}

sub strip_plan {
    my $self = shift;
    $self->skipspace;
    return unless $self->strip_string('>>');

    $self->skipspace;

    my($plan) = $self->looking_at(qr/(\+?\d+|no_plan)/);
    $self->strip_string($plan);
    return $plan;
}

sub strip_testclass_name {
    my $self = shift;
    $self->skipspace;

    ! $self->looking_at(qr/^(?:uses|ex(?:tends|ercises))/, 9)
    && $self->strip_name;
}

sub strip_options {
    my $self = shift;
    $self->skipspace;

    my %ret;

    while (!$self->looking_at(qr/[{"]/)) {
        defined $self->strip_base_classes(\%ret)     ? () 
      : defined $self->strip_helper_classes(\%ret)   ? ()
      : defined $self->strip_class_under_test(\%ret) ? ()
      : croak 'Expected option name';
        $self->skipspace;
    }

    return \%ret;
}


sub strip_class_under_test {
    my($self, $opts) = @_;
    return unless $self->strip_string('exercises');

    croak "testclass can only exercise one class" if $opts->{class_under_test};

    my $name = $self->strip_name;
    croak "Expected a class name" unless defined $name;
    $opts->{class_under_test} = $name;
    return 1;
}


sub strip_helper_classes {
    my($self, $opts) = @_;
    return unless $self->strip_string('uses');

    $opts->{helpers} = [] unless defined $opts->{helpers};

    while (1) {
        $self->skipspace;
        my $helper = '';
        if ($self->strip_string('-')) {
            $helper .= 'Test::';
        }

        my $name = $self->strip_name;
        $helper .= $name;
        push @{$opts->{helpers}}, $helper;
        return 1 unless $self->strip_comma;
    }
}

sub strip_base_classes {
    my($self, $ret) = @_;
    return unless $self->strip_string('extends');

    while (1) {
        $self->skipspace;

        my $baseclass = $self->strip_name;
        croak 'expecting a base class' unless defined $baseclass;
        $ret->{base} .= "$baseclass ";
        return 1 unless $self->strip_comma;
    }
}

sub strip_comma {
    my $self = shift;
    $self->skipspace;
    $self->strip_string(',');
}

sub strip_string {
    my($self, $expected) = @_;

    return unless $self->looking_at($expected);

    $self->alter_buffer(sub { s/^\Q$expected\E// });
    return 1;
}

sub alter_buffer {
    my($self, $sub) = @_;

    local $_ = $self->get_buffer;
    $sub->();
    $self->set_buffer($_);
}

sub get_buffer {
    my $self = shift;
    my $linestr = $self->get_linestr;
    substr($linestr, $self->offset)
}

sub set_buffer {
    my($self, $new) = @_;

    my $linestr = $self->get_linestr;
    substr($linestr, $self->offset) = $new;
    $self->set_linestr($linestr);
    return $new;
}

sub extend_buffer {
    my $self = shift;
    my $buffer = $self->get_buffer;
    $self->set_buffer('');
    $self->skipspace;
    $buffer .= $self->get_buffer;
    $self->set_buffer($buffer);
}

1;
__END__

=head1 NAME

Test::Class::Sugar::Context - Pay no attention to the class behind the curtain

=head1 DESCRIPTION

Test::Class::Sugar::Context does most of the heavy lifting for
Test::Class::Sugar's parser. No user serviceable parts inside and all that.

However, if you're writing your own module using L<Devel::Declare> and, like I
was, you're looking at other D::D client modules to lift ideas from, then you
probably want to take a look at the following selected methods:

=over

=item B<looking_at($expected, $len)>

Look at the unparsed buffer and returns true if it
matches C<$expected>. Given a C<$len> argument, looking_at first makes sure
that there are at least $len characters in the buffer.

=item B<get_buffer>, B<set_buffer>

Getters and setters. Like B<get_linestr> and B<set_linestr> but, rather than
return the whole C<linestr>, they only return the unparsed bit of it. If you
too are sick of writing C<< substr($ctx->get_linestr, $ctx->offset) >>, then
these are the methods for you.

=item B<alter_buffer(CODE)>

It works like this:

    $ctx->alter_buffer(sub { s/bibble// }

Obvious no?

B<alter_buffer> temporarily copies the buffer into C<$_>, then calls the
coderef you pass in, then writes the new value of C<$_> back into the
buffer. It's not quite the same as having a fully mutable buffer, but it'll
just have to serve.

=item B<extend_buffer>

Grabs the next linestr and appends it to the buffer.

=back

=head1 DIAGNOSTICS

Only kidding. Right now the diagnostics suck harder than a thing that sucks
very hard indeed. One of these days I'll work out how to have a parser fail
gracefully with meaningful diagnostics, but today is not that day.

=head1 BUGS AND LIMITATIONS

There's bound to be some. Patches welcome.

Please report any bugs or feature requests to me. It's unlikely you'll get any
response if you use L<http://rt.cpan.org> though. Your best course of action
is to fork the project L<http://www.github.com/pdcawley/test-class-sugar>,
write at least one failing test (Write something in C<testclass> form that
should work, but doesn't. If you can arrange for it to fail gracefully, then
please do, but if all you do is write something that blows up spectacularly,
that's good too. Failing/exploding tests are like manna to a maintenance
programmer.

=head1 AUTHOR

Piers Cawley C<< <pdcawley@bofh.org.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Piers Cawley C<< <pdcawley@bofh.org.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
