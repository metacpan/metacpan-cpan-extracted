package SVN::Hooks::Mailer;
# ABSTRACT: Send emails after successful commits.
$SVN::Hooks::Mailer::VERSION = '1.36';
use strict;
use warnings;

use Carp;
use SVN::Hooks;

use Exporter qw/import/;
my $HOOK = 'MAILER';
our @EXPORT = qw/EMAIL_CONFIG EMAIL_COMMIT/;


sub _deprecated {
    croak <<"EOS";
DEPRECATED: The SVN::Hooks::Mailer plugin was deprecated in 2008 and
became nonoperational in version 1.08. You must edit your hook
configuration to remove the directives EMAIL_CONFIG and
EMAIL_COMMIT. You may use the new SVN::Hooks::Notify plugin for
sending email notifications.
EOS
}


sub EMAIL_CONFIG {
    _deprecated();
}


sub EMAIL_COMMIT {
    _deprecated();
}


1; # End of SVN::Hooks::Mailer

__END__

=pod

=encoding UTF-8

=head1 NAME

SVN::Hooks::Mailer - Send emails after successful commits.

=head1 VERSION

version 1.36

=head1 SYNOPSIS

This SVN::Hooks plugin is deprecated. You should use
SVN::Hooks::Notify instead.

=over

=item EMAIL_CONFIG

=item EMAIL_COMMIT

=back

=head1 AUTHOR

Gustavo L. de M. Chaves <gnustavo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by CPqD <www.cpqd.com.br>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
