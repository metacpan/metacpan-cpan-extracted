#!/usr/bin/perl
##############################################################################
# 	Copyright (c) 2000-2006 All rights reserved
# 	Alberto Reggiori <areggiori@webweaving.org>
#	Dirk-Willem van Gulik <dirkx@webweaving.org>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer. 
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# 3. The end-user documentation included with the redistribution,
#    if any, must include the following acknowledgment:
#       "This product includes software developed by 
#        Alberto Reggiori <areggiori@webweaving.org> and
#        Dirk-Willem van Gulik <dirkx@webweaving.org>."
#    Alternately, this acknowledgment may appear in the software itself,
#    if and wherever such third-party acknowledgments normally appear.
#
# 4. All advertising materials mentioning features or use of this software
#    must display the following acknowledgement:
#    This product includes software developed by the University of
#    California, Berkeley and its contributors. 
#
# 5. Neither the name of the University nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# 6. Products derived from this software may not be called "RDFStore"
#    nor may "RDFStore" appear in their names without prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESSED OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#
# ====================================================================
#
# This software consists of work developed by Alberto Reggiori and 
# Dirk-Willem van Gulik. The RDF specific part is based on public 
# domain software written at the Stanford University Database Group by 
# Sergey Melnik. For more information on the RDF API Draft work, 
# please see <http://www-db.stanford.edu/~melnik/rdf/api.html>
# The DBMS TCP/IP server part is based on software originally written
# by Dirk-Willem van Gulik for Web Weaving Internet Engineering m/v Enschede,
# The Netherlands.
#
##############################################################################

my $Usage =<<EOU;
Usage is:
    $0 [-h] [-input_dir <valid_directoryname>] [-output_dir <valid_directoryname>]

Convert POD documentation to HTML - starting from a given input directory it recursevly traverses it looking for *.pm files and converts
the documentation to HTML using pod2html. The branch structure of the input dir containing the POD files is assured to be recreated into
the out directory.

-h	Print this message

[-input_dir <valid_directoryname>]
	Input directory of existing DB files. Default is cwd.

[-output_dir <valid_directoryname>]
	Output directory where to generate the HTML formatted documentation

[-v]
	verbose		

EOU

# Process options
print $Usage and exit if ($#ARGV<0);

my ($verbose,$input_dir,$output_dir);
my @query;
while (defined($ARGV[0]) and $ARGV[0] =~ /^[-+]/) {
    my $opt = shift;

    if ($opt eq '-h') {
        print $Usage;
        exit;
    } elsif ($opt eq '-v') {
        $verbose=1;
    } elsif ($opt eq '-input_dir') {
	$opt=shift;
	$input_dir = $opt
                if(-e $opt);
    } elsif ($opt eq '-output_dir') {
	$opt=shift;
	$output_dir = $opt
                if(-e $opt);
    } else {
        die "Unknown option: $opt\n$Usage";
    };
};

my $pod2html = '/usr/bin/pod2html';
my $find = '/usr/bin/find';

$input_dir= '.' unless($input_dir);
$output_dir= '.' unless($output_dir);

open(PM,"$find $input_dir -name '*.pm' -print |");
while (<PM>) {
	chomp;
	my $pod_file = $_;
	my $html_dir = $pod_file;
	$html_dir =~ s#$input_dir/##;
	my $html_file = $1
		if $html_dir =~ s#([^/]+)$##;
	`mkdir -p $output_dir$html_dir`;
	$html_file =~ s/.pm/.html/;
	$html_file = $output_dir.$html_dir.$html_file;
	print "Generating HTML documentation for $pod_file ......" if($verbose);
	if ( $verbose ) {
		`$pod2html $pod_file > $html_file`;
	} else {
		`$pod2html $pod_file > $html_file 2> /dev/null`;
		};
	print "DONE\n" if($verbose)
	};
unlink('pod2htmd.x~~');
unlink('pod2htmi.x~~');
close(PM);
