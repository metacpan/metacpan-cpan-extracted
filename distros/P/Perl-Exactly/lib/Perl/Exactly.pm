package Perl::Exactly;
######################################################################
#
# Perl::Exactly - ensures exactly version of perl
#
# http://search.cpan.org/dist/Perl-Exactly/
#
# Copyright (c) 2014, 2015, 2017, 2018, 2019 INABA Hitoshi <ina@cpan.org> in a CPAN
######################################################################

$VERSION = '0.06';
$VERSION = $VERSION;

use 5.00503;
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;

if ($0 eq __FILE__) {
    print $];
    exit;
}

sub VERSION {
    my(undef, $exactly_perl_version) = @_;

    if ($] !~ m/\A \Q$exactly_perl_version\E/oxms) {
        if (not -e "@{[__FILE__]}.conf") {
            _croak("@{[__FILE__]}: @{[__FILE__]}.conf not exists, stopped");
        }

        # load configuration file
        my %perlbin = %{ (do "@{[__FILE__]}.conf") || {} };

        if (not exists $perlbin{$exactly_perl_version}) {
            _croak("Path of perl $exactly_perl_version not defined in @{[__FILE__]}.conf, stopped");
        }
        elsif (not -e $perlbin{$exactly_perl_version}) {
            _croak("$perlbin{$exactly_perl_version} in @{[__FILE__]}.conf not exists, stopped");
        }
        elsif (`$perlbin{$exactly_perl_version} @{[__FILE__]}` !~ m/\A \Q$exactly_perl_version\E/oxms) {
            _croak("$perlbin{$exactly_perl_version} isn't perl $exactly_perl_version, stopped");
        }
        else {
            my @switch = ();
            if ($^W) {
                push @switch, '-w';
            }
            if (defined $^I) {
                push @switch, '-i' . $^I;
                undef $^I;
            }

            # DOS-like system
            if ($^O =~ m/\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) {
                exit _systemx(
                    _escapeshellcmd_MSWin32($perlbin{$exactly_perl_version}),

                # -I switch can not treat space included path
                #   (map { '-I' . _escapeshellcmd_MSWin32($_) } @INC),
                    (map { '-I' .                         $_  } @INC),

                    @switch,
                    '--',
                    map { _escapeshellcmd_MSWin32($_) } $0, @ARGV
                );
            }

            # UNIX-like system
            else {
                exit _systemx(
                    _escapeshellcmd($perlbin{$exactly_perl_version}),
                    (map { '-I' . _escapeshellcmd($_) } @INC),
                    @switch,
                    '--',
                    map { _escapeshellcmd($_) } $0, @ARGV
                );
            }
        }
    }
}

# escape shell command line on DOS-like system
sub _escapeshellcmd_MSWin32 {
    my($word) = @_;
    if ($word =~ m/ [ ] /oxms) {
        return qq{"$word"};
    }
    else {
        return $word;
    }
}

# escape shell command line on UNIX-like system
sub _escapeshellcmd {
    my($word) = @_;
    return $word;
}

# safe system
sub _systemx {
    $| = 1;

    # local $ENV{'PATH'} = '.';
    local @ENV{qw(IFS CDPATH ENV BASH_ENV)}; # Make %ENV safer

    return CORE::system { $_[0] } @_; # safe even with one-argument list
}

# instead of Carp::croak
sub _croak {
    my($package,$filename,$line) = caller(1);
    print STDERR "@_ at $filename line $line.\n";
    die "\n";
}

1;

__END__

=pod

=head1 NAME

Perl::Exactly - ensures exactly version of perl

=head1 SYNOPSIS

  use Perl::Exactly 5.005; # ensures perl is 5.005
  use Perl::Exactly 5.016; # ensures perl is 5.016, but doesn't "use strict" and "use feature"

=head1 DESCRIPTION

  Perl::Exactly ensures that perl interpreter matches to required version
  exactly. If running perl doesn't match required version then Perl::Exactly
  finds it using Perl/Exactly.pm.conf, and executes script again on it.
  When exactly version of perl not found, script will die.

=head1 INSTALLATION

  1. Copy Perl/Exactly.pm and Perl/Exactly.pm.conf to @INC directory.

=head1 CONFIGURATION

  1. Edit Perl/Exactly.pm.conf to define paths of perls.

=head1 SAMPLE of Perl/Exactly.pm.conf

  # Configuration file of Perl/Exactly.pm
  +{
      # DOS-like system
      ($^O =~ m/\A (?: MSWin32 | NetWare | symbian | dos ) \z/oxms) ?
      (
          5.005 => 'C:/Perl/bin/perl.exe',
          5.006 => 'C:/Perl56/bin/perl.exe',
          5.008 => 'C:/Perl58/bin/perl.exe',
          5.010 => 'C:/Perl510/bin/perl.exe',
          5.012 => 'C:/Perl512/bin/perl.exe',
          5.014 => 'C:/Perl514/bin/perl.exe',
          5.016 => 'C:/Perl516/bin/perl.exe',
          5.018 => 'C:/Perl518/bin/perl.exe',
          5.020 => 'C:/Perl520/bin/perl.exe',
          5.022 => 'C:/Perl522/bin/perl.exe',
          5.024 => 'C:/Perl524/bin/perl.exe',
          5.026 => 'C:/Perl526/bin/perl.exe',
          5.028 => 'C:/Perl528/bin/perl.exe',
          5.030 => 'C:/Perl530/bin/perl.exe',
      ) :

      # UNIX-like system
      (
          5.005 => '/path/to/perl/5.005/bin/perl',
          5.006 => '/path/to/perl/5.006/bin/perl',
          5.008 => '/path/to/perl/5.008/bin/perl',
          5.010 => '/path/to/perl/5.010/bin/perl',
          5.012 => '/path/to/perl/5.012/bin/perl',
          5.014 => '/path/to/perl/5.014/bin/perl',
          5.016 => '/path/to/perl/5.016/bin/perl',
          5.018 => '/path/to/perl/5.018/bin/perl',
          5.020 => '/path/to/perl/5.020/bin/perl',
          5.022 => '/path/to/perl/5.022/bin/perl',
          5.024 => '/path/to/perl/5.024/bin/perl',
          5.026 => '/path/to/perl/5.026/bin/perl',
          5.028 => '/path/to/perl/5.028/bin/perl',
          5.030 => '/path/to/perl/5.030/bin/perl',
      )
  }
  __END__

=head1 AUTHOR

  INABA Hitoshi E<lt>ina@cpan.orgE<gt> in a CPAN

  This project was originated by INABA Hitoshi.

=head1 LICENSE AND COPYRIGHT

  This software is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself. See L<perlartistic>.

  This software is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SEE ALSO

  ina - CPAN
  http://search.cpan.org/~ina/

  BackPAN - A Complete History of CPAN
  http://backpan.perl.org/authors/id/I/IN/INA/

=cut
