use strict;
use warnings;

package Task::BeLike::Shantanu;

# PODNAME: Task::BeLike::Shantanu
# ABSTRACT: All my default Modules in a perl installation
our $VERSION = '0.10'; # VERSION
# Dependencies

use 5.010;
use Acme::CPANAuthors::India;
use Dist::Zilla::PluginBundle::SHANTANU;
use File::UStore;
use Pod::Weaver::PluginBundle::SHANTANU;

use autodie;
use App::cpanminus;
use Authen::Passphrase;
use Catalyst 5.90000;
use Catalyst::Plugin::Assets;
use Catalyst::Plugin::Authentication;
use Catalyst::Plugin::Session;
use Catalyst::Plugin::Session::Store::FastMmap;
use Catalyst::Plugin::StatusMessage;
use Data::Dumper 2.14;
use DateTime::Format::MySQL;
use DBIx::Class;
use DBIx::Class::PassphraseColumn;
use DBIx::Class::Validation;
use DBIx::Class::InflateColumn::Authen::Passphrase;
use Digest::MD5;
use Dist::Zilla 4.300000;
use ExtUtils::MakeMaker 6.60;
use ExtUtils::ParseXS 3.10;
use File::ChangeNotify 0.23;
use File::Copy 2.20;
use File::Find::Rule 0.33;
use File::HomeDir 1.00;
use File::Spec 3.40;
use JSON::XS;
2.33;
use Log::Log4perl 1.40;
use Moose 2.06;
use Perl::Critic;
use Perl::Tidy;
use Test::Pod 1.48;
use Pod::Simple 3.28;
use Starman 0.30;
use YAML 0.84;
use YAML::XS 0.38;

1;

__END__

=pod

=head1 NAME

Task::BeLike::Shantanu - All my default Modules in a perl installation

=head1 VERSION

version 0.10

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/task-belike-shantanu/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/task-belike-shantanu>

  git clone git://github.com/shantanubhadoria/task-belike-shantanu.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org>

=head1 CONTRIBUTOR

Shantanu <shantanu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
