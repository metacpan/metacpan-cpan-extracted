package MooseX::AttributeHelpers::MethodProvider::String;
use Moose::Role;

our $VERSION = '0.25';

sub append : method {
    my ($attr, $reader, $writer) = @_;

    return sub { $writer->( $_[0],  $reader->($_[0]) . $_[1] ) };
}

sub prepend : method {
    my ($attr, $reader, $writer) = @_;

    return sub { $writer->( $_[0],  $_[1] . $reader->($_[0]) ) };
}

sub replace : method {
    my ($attr, $reader, $writer) = @_;

    return sub {
        my ( $self, $regex, $replacement ) = @_;
        my $v = $reader->($_[0]);

        if ( (ref($replacement)||'') eq 'CODE' ) {
            $v =~ s/$regex/$replacement->()/e;
        } else {
            $v =~ s/$regex/$replacement/;
        }

        $writer->( $_[0], $v);
    };
}

sub match : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $reader->($_[0]) =~ $_[1] };
}

sub chop : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $v = $reader->($_[0]);
        CORE::chop($v);
        $writer->( $_[0], $v);
    };
}

sub chomp : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $v = $reader->($_[0]);
        chomp($v);
        $writer->( $_[0], $v);
    };
}

sub inc : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $v = $reader->($_[0]);
        $v++;
        $writer->( $_[0], $v);
    };
}

sub clear : method {
    my ($attr, $reader, $writer) = @_;
    return sub { $writer->( $_[0], '' ) }
}

sub length : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $v = $reader->($_[0]);
        return CORE::length($v);
    };
}

sub substr : method {
    my ($attr, $reader, $writer) = @_;
    return sub {
        my $self = shift;
        my $v = $reader->($self);

        my $offset      = defined $_[0] ? shift : 0;
        my $length      = defined $_[0] ? shift : CORE::length($v);
        my $replacement = defined $_[0] ? shift : undef;

        my $ret;
        if (defined $replacement) {
            $ret = CORE::substr($v, $offset, $length, $replacement);
            $writer->($self, $v);
        }
        else {
            $ret = CORE::substr($v, $offset, $length);
        }

        return $ret;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::AttributeHelpers::MethodProvider::String

=head1 VERSION

version 0.25

=head1 DESCRIPTION

This is a role which provides the method generators for
L<MooseX::AttributeHelpers::String>.

=head1 METHODS

=over 4

=item B<meta>

=back

=head1 PROVIDED METHODS

=over 4

=item B<append>

=item B<prepend>

=item B<replace>

=item B<match>

=item B<chomp>

=item B<chop>

=item B<inc>

=item B<clear>

=item B<length>

=item B<substr>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-AttributeHelpers>
(or L<bug-MooseX-AttributeHelpers@rt.cpan.org|mailto:bug-MooseX-AttributeHelpers@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHOR

Stevan Little <stevan@iinteractive.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Stevan Little and Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
