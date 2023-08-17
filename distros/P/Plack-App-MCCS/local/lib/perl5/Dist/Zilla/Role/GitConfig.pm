package Dist::Zilla::Role::GitConfig;

our $VERSION = '0.92'; # VERSION
# ABSTRACT: Easy role to add git_config option to most plugins

#############################################################################
# Modules

use Moose::Role;
use MooseX::Types::Moose qw(Str RegexpRef);

use List::Util qw(first);

use String::Errf qw(errf);  # We are here to save the errf: E-R-R-F!

use namespace::clean;

#############################################################################
# Requirements

requires qw(log_fatal zilla _git_config_mapping);

#############################################################################
# Attributes

has git_config => (
   is        => 'ro',
   isa       => Str,
);

#############################################################################
# Pre/post-BUILD

around BUILDARGS => sub {
   my $orig = shift;
   my $self = shift;
   my %opts = @_ == 1 ? %{$_[0]} : @_;

   my $zilla = $opts{zilla};

   if ($opts{git_config}) {
      my $config = first {
         $_->isa('Dist::Zilla::Plugin::Config::Git') && $_->plugin_name eq $opts{git_config}
      } @{ $zilla->plugins };

      $self->log_fatal(['No Config::Git plugin found called "%s"', $opts{git_config}])
         unless $config;

      my $mapping = $self->_git_config_mapping;
      my @mvps    = $self->can('mvp_multivalue_args') ? $self->mvp_multivalue_args : ();

      # Map configuration to different attributes
      foreach my $option (sort keys %$mapping) {
         my $errf_str = $mapping->{$option};

         my $val = errf $errf_str, {
            map { $_ => $config->$_() } qw( remote local_branch remote_branch changelog )
         };

         # Don't overwrite if option already exists
         unless (exists $opts{$option}) {
            $opts{$option} = (grep { $_ eq $option } @mvps) ? [ $val ] : $val;
         }
      }

      ### XXX: This should probably be more dynamic...
      if ($self->can('allow_dirty') && !exists $opts{'allow_dirty'}) {
         if ($self->can('allow_dirty_match')) {
            $opts{'allow_dirty'}       = [ grep {       Str->check($_) } @{ $config->allow_dirty } ];
            $opts{'allow_dirty_match'} = [ grep { RegexpRef->check($_) } @{ $config->allow_dirty } ];
         }
         else {
            $opts{'allow_dirty'} = [ @{ $config->allow_dirty } ];
         }
      }
   }

   $orig->($self, %opts);
};

42;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::GitConfig - Easy role to add git_config option to most plugins

=head1 SYNOPSIS

    package Dist::Zilla::Plugin::GitReleasePlugin;
 
    use Moose;
 
    with 'Dist::Zilla::Role::BeforeRelease';
    with 'Dist::Zilla::Role::GitConfig';
 
    sub _git_config_mapping { +{
       push_to   => '%{remote}s %{local_branch}s:%{remote_branch}s',
       changelog => '%{changelog}s',
    } }

=head1 DESCRIPTION

This is an easy-to-use role for plugins to enable usage of L<Config::Git|Dist::Zilla::Plugin::Config::Git> configurations.

=head1 REQUIREMENTS

=head2 _git_config_mapping

Hashref of option to L<errf|String::Errf> string mappings.

The mappings don't work for C<<< allow_dirty >>>.  These are (currently) hardcoded to map to C<<< allow_dirty >>> and C<<< allow_dirty_match >>> options
directly.

=head1 AVAILABILITY

The project homepage is L<https://github.com/SineSwiper/Dist-Zilla-Plugin-Config-Git>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Dist::Zilla::Plugin::Config::Git/>.

=head1 AUTHOR

Brendan Byrd <BBYRD@CPAN.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Brendan Byrd.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
