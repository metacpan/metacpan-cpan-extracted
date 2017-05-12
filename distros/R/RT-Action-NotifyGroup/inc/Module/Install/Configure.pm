#line 1 "inc/Module/Install/Configure.pm - /usr/lib/perl5/site_perl/5.8.5/Module/Install/Configure.pm"
package Module::Install::Configure;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

use strict;

$Module::Install::Configure::VERSION = '0.01';

require File::Temp;

#line 13

sub Configure
{
	my $self = shift;
	my $opt = shift;
	my @file = @_;

	foreach my $f (@file) {
		unless( -f $f && -r _ ) {
			print STDERR "Couldn't find file '$_'\n";
			next;
		}
		unless( -w _ ) {
			print STDERR "Permission denied\n";
			next;
		}
		$self->__rewrite_file( $opt, $f );
	}

	return;
}

sub __rewrite_file
{
	my ($self, $opt, $fname) = @_;

	my $re_opts = join('|', map {"\Q$_"} keys %$opt );

	my $fh;
	my $mode = (stat($fname))[2];
	open TARGET, "<$fname";
	my ($tmpfh, $tmpfname) = File::Temp::tempfile('mi-conf-XXXX', UNLINK => 1);
	while( my $str = <TARGET> ) {
		print $tmpfh $str;
		if( $str =~ /^###\s*replace: ?(.*)$/ ) {
			my $nstr = $1;
			$nstr =~ s/\@($re_opts)\@/$opt->{$1}/ge;
			# skip one line;
			<TARGET>;
			print $tmpfh $nstr;
			print $tmpfh "\n";
		}
	}
	close TARGET;
	unlink "$fname";
	open TARGET, ">$fname";
	seek $tmpfh, 0, 0;
	while( <$tmpfh> ) {
		print TARGET "$_";
	}
	close TARGET;
	chmod $mode, $fname;
}

1;
