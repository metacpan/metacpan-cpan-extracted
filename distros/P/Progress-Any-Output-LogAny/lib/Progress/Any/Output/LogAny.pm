package Progress::Any::Output::LogAny;

use 5.010;
use strict;
use warnings;

use Log::Any;

our $VERSION = '0.04'; # VERSION

sub new {
    my ($class, %args) = @_;

    $args{template} //= "(%c/%C) %m";
    $args{logger} //= Log::Any->get_logger();
    bless \%args, $class;
}

sub update {
    my ($self, %args) = @_;

    my $msg = $args{message};
    return unless defined($msg);

    my $meth = "debug";
    my $level = $args{level} // "normal";
    if ($level eq 'low') {
        $meth = "trace";
    } elsif ($level eq 'high') {
        $meth = "info";
    }

    my $s = $args{indicator}->fill_template($self->{template}, %args);
    $self->{logger}->$meth($s);
}

1;
# ABSTRACT: Output progress to Log::Any

__END__

=pod

=encoding UTF-8

=head1 NAME

Progress::Any::Output::LogAny - Output progress to Log::Any

=head1 VERSION

This document describes version 0.04 of Progress::Any::Output::LogAny (from Perl distribution Progress-Any-Output-LogAny), released on 2014-07-29.

=head1 SYNOPSIS

 use Progress::Any::Output;

 Progress::Any::Output->set("LogAny",
     logger   => $log,
     template => '(%c/%C) %m',
 );

=head1 DESCRIPTION

This output sends progress update to Log::Any. Only progress update() containing
message will be logged, unless C<has_message_only> attribute is set to false.
Logging is done at loglevel C<debug>, but when update C<level> is set to
C<high>, message will be logged at loglevel C<info>. When update C<level> is set
to C<low>, message will be logged at loglevel C<trace>.

=for Pod::Coverage ^(update)$

=head1 METHODS

=head2 new(%args) => OBJ

Instantiate. Usually called through C<<
Progress::Any::Output->set("LogAny", %args) >>.

Known arguments:

=over

=item * logger => OBJ

Logger object to use. Defaults to C<< Log::Any->get_logger() >>.

=item * template => STR (default: '(%c/%C) %m')

Will be used to do C<< $progress->fill_template() >>. See L<Progress::Any> for
supported template strings.

=item * has_message_only => BOOL (default: 1)

By default, when set to 1, will cause output to only log progress update()'s
which contains message. If set to 0, will log all progress update()'s.

=back

=head1 SEE ALSO

L<Progress::Any>

L<Log::Any>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Progress-Any-Output-LogAny>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Progress-Any-Output-LogAny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Progress-Any-Output-LogAny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
