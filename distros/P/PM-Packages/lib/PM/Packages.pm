package PM::Packages;

use 5.00405;
use strict;

our $VERSION = '0.01';

our @EXPORT_OK = qw( pm_packages );
our @EXPORT = @EXPORT_OK;

use Exporter qw( import );

sub pm_packages
{
    my( $pmfile ) = @_;
    my @ret;

    open my $fh, "<", "$pmfile" or return;

    local $/ = "\n";
    my $inpod = 0;
  PLINE: while (<$fh>) {
        chomp;
        my($pline) = $_;
        $inpod = $pline =~ /^=(?!cut)/ ? 1 :
            $pline =~ /^=cut/ ? 0 : $inpod;
        next if $inpod;
        next if substr($pline,0,4) eq "=cut";

        $pline =~ s/\#.*//;
        next if $pline =~ /^\s*$/;
        if ($pline =~ /^__(?:END|DATA)__\b/
            and $pmfile !~ /\.PL$/   # PL files may well have code after __DATA__
            ){
            last PLINE;
        }

        my $pkg; 
        my $strict_version;

        if (
            $pline =~ m{
                      (.*)
                      (?<![*\$\\@%&]) # no sigils
                      \bpackage\s+
                      ([\w\:\']+)
                      \s*
                      (?: $ | [\}\;] | \{ | \s+($version::STRICT) )
                    }x) {
            $pkg = $2;
            $strict_version = $3;
            if ($pkg eq "DB"){
                # XXX if pumpkin and perl make him comaintainer! I
                # think I always made the pumpkins comaint on DB
                # without further ado (?)
                next PLINE;
            }
        }

        if ($pkg) {
            # Found something

            # from package
            $pkg =~ s/\'/::/;
            # next PLINE unless $pkg =~ /^[A-Za-z]/;
            next PLINE unless $pkg =~ /\w$/;
            next PLINE if $pkg eq "main";
            # Perl::Critic::Policy::TestingAndDebugging::ProhibitShebangWarningsArg
            # database for modid in mods, package in packages, package in perms
            # alter table mods modify modid varchar(128) binary NOT NULL default '';
            # alter table packages modify package varchar(128) binary NOT NULL default '';
            next PLINE if length($pkg) > 128;
            push @ret, $pkg;
        }
    }

    $fh->close;  
    return @ret;    
}


1;
__END__

=head1 NAME

PM::Packages - Find all packages from a .pm file

=head1 SYNOPSIS

    use PM::Packages;

    my @packages = pm_packages( "Honk/Bonk.pm" );

=head1 DESCRIPTION

C<pm_packages> returns all packages a given file creates.  It does this by
doing a text scan of the file, looking for lines that start with C<package>. 
It ignores POD, __END__ and __DATA__.  

It will ignore a package that is split onto two lines.
    
    package
        Is::Ignored;

It can not detect packages that are created programatically.

This code was copied from PAUSE::pmfile::packages_per_pmfile.


=head1 AUTHOR

Philip Gwyn, E<lt>gwyn -AT- cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Philip Gwyn

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.26.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
