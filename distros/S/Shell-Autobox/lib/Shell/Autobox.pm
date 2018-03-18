package Shell::Autobox;

use strict;
use warnings;

use base qw(autobox);

use Carp qw(confess);
use File::Temp;

our $VERSION = '0.40.0';

sub import {
    my $class  = shift;
    my $caller = (caller)[0];

    for my $program (@_) {
        my $sub = sub {
            my $input = shift;
            my $args = join ' ', @_;
            my $maybe_args = length($args) ? " $args" : '';
            my $maybe_stdin = '';
            my $stdout = File::Temp->new();
            my $stderr = File::Temp->new();
            my $stdin;

            if (defined($input) && length($input)) {
                $stdin = File::Temp->new();
                print $stdin $input;
                $maybe_stdin = " < $stdin";
            }

            my $command = sprintf(
                '%s%s%s 2> %s > %s',
                $program,
                $maybe_args,
                $maybe_stdin,
                $stderr,
                $stdout
            );

            my ($output, $error);

            my $fail = system $command;

            {
                local $/ = undef;
                $error  = <$stderr>;
                $output = <$stdout>;
            }

            my $maybe_error = $error =~ /\S/ ? ": $error" : '';
            my $message = "$program$maybe_args$maybe_error";

            if ($fail) {
                confess "can't exec $message";
            } elsif ($maybe_error) {
                warn "error running $message";
            }

            return $output;
        };

        {
            no strict 'refs';
            *{"$caller\::$program"} = $sub;
        }
    }

    $class->SUPER::import(SCALAR => $caller);
}

1;

__END__

=head1 NAME

Shell::Autobox - pipe Perl strings through shell commands

=head1 SYNOPSIS

    use Shell::Autobox qw(xmllint);

    my $xml = '<foo bar="baz"><bar /><baz /></foo>';
    my $pretty = $xml->xmllint('--format -');

=head1 DESCRIPTION

Shell::Autobox provides an easy way to pipe Perl strings through shell commands. Commands passed as arguments to the
C<use Shell::Autobox> statement are installed as subroutines in the calling package, and that package is then
registered as the handler for methods called on ordinary (i.e. non-reference) scalars.

When a method corresponding to a registered command is called on a scalar, the scalar is passed as the command's standard input;
additional arguments are passed through as a space-delimited list of options, and - if no error occurs - the
command's standard output is returned. This can then be piped into other commands.

The registered methods can also be called as regular functions e.g.

    use Shell::Autobox qw(cut);

    my $bar = cut("foo:bar:baz", "-d':' -f2");

=head2 EXPORT

None by default.

=head1 SEE ALSO

=over

=item * L<autobox>

=item * L<autobox::Core>

=item * L<Shell>

=back

=head1 AUTHOR

chocolateboy <chocolate@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2018 by chocolateboy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=head1 VERSION

0.40.0

=cut
