package Mojolicious::Plugin::GitConfig::Config;
$Mojolicious::Plugin::GitConfig::Config::VERSION = '1.0';
# ABSTRACT: extended Config:GitLike class to use git repository config files
use Mojo::Base 'Config::GitLike';

sub global_file {
  return "/etc/gitconfig";
}

sub user_file {
  return $ENV{HOME} . "/.gitconfig";
}

sub dir_file {
  return ".git/config";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::GitConfig::Config - extended Config:GitLike class to use git repository config files

=head1 VERSION

version 1.0

=head1 AUTHOR

Dominik Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Mojolicious::Plugin::GitConfig/>.

=head1 BUGS

Please report any bugs or feature requests by email to
L<byterazor@federationhq.de|mailto:byterazor@federationhq.de>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
