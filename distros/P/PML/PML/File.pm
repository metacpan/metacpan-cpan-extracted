#! /usr/bin/perl -w
################################################################################
#
# File.pm (do cool things with files)
#
################################################################################
#
# Package
#
################################################################################
package PML::File;
################################################################################
#
# Includes
#
################################################################################
use strict;
################################################################################
#
# Global Variables and Default Settings
#
################################################################################
use vars qw($VERSION $DATE $ID);
$VERSION	= '0.01';
$DATE		= 'Wed May 24 16:58:17 2000';
$ID		= '$Id: File.pm,v 1.4 2000/07/31 17:13:46 pjones Exp $';

my $pkg = 'file::';
my $local = "${pkg}local";
my $prefix = "${pkg}prefix";
my $dprefix = 'conf';
################################################################################
#
# Code Start
#
################################################################################
PML->register(name=>"${pkg}cat", token=>\&cat);
PML->register(name=>"${pkg}conf",token=>\&conf);
################################################################################
#
# ==== cat ==== ################################################################
#
#   Arguments:
#	See PML Docs
#
#     Returns:
#	The contents of the files
#
# Description:
#	Returns the contents of a bunch of files
#
################################################################################
sub cat
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my (@files, $file, $result);
	
	@files = $self->tokens_execute($a);
	
	foreach $file (@files) {
		unless (open CAT, $file) {
			if ($self->warning) {
				print STDERR "can't open file '$file': $!\n";
			}
			next;
		}
		
		$result .= join '', <CAT>;
		close CAT;
	}
	
	return $result;
} # <-- End cat -->
################################################################################
#
# ==== conf ==== ###############################################################
#
#   Arguments:
#	See PML Docs
#
#     Returns:
#	Nothing
#
# Description:
#	Loads variables from config file
#
################################################################################
sub conf
{
	my ($self, $token) = @_;
	my ($name, $a, $b) = @{$token->data};
	my (@files, $file, $key, $value, $lastline);
	
	@files = $self->tokens_execute($a);
	
	foreach $file (@files) {
		unless (open CONF, $file) {
			if ($self->warning) {
				print STDERR "can't open file '$file': $!\n";
			}
			next;
		}
		
		$lastline = '';
		while (<CONF>) {
			next if /^\s*$/ or /^\s*#/;
			
			if (s|\\$||) {
				chomp;
				$lastline =~ s/\s+$/ /; s/^\s+//;
				$lastline .= $_;
				next unless eof CONF;
			}
			
			if (length $lastline) {
				$lastline =~ s/\s+$/ /; s/^\s+//;
				$_ = $lastline . $_;
				$lastline = '';
			}
				
			s/^\s+//; s/\s+$//; chomp;
			($key, $value) = split(/\s*=\s*/, $_, 2);
			
			unless ($key) {
				if ($self->warning) {
					print STDERR "no config variable on line $. of file '$file'\n";
				}
				next;
			}
			
			if ($self->[PML->PML_V]{$local}) {
				$self->[PML->PML_V]{$key} =  $value || '';
			} elsif ($self->[PML->PML_V]{$prefix}) {
				$self->[PML->PML_V]{$self->[PML->PML_V]{$prefix}}{$key} = $value;
			} else {
				$self->[PML->PML_V]{$dprefix}{$key} = $value;
			}
		}
		
		close CONF;
	}
	
	return undef;
} # <-- End conf -->
################################################################################
#                              END-OF-SCRIPT                                   #
################################################################################
=head1 NAME

File.pm

=head1 SYNOPSIS

Quick Usage

=head1 DESCRIPTION

What does it do?

=head1 OPTIONS

Long Usage

=head1 EXAMPLES

Example usage

=head1 SEE ALSO

perl(1)

=head1 AUTHOR

Peter J Jones
pjones@cpan.org

=cut

1;
__END__


