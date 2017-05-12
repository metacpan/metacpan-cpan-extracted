############################################################
#
#   $Id: Bot.pm 483 2006-05-22 21:36:46Z nicolaw $
#   Parse::Colloquy::Bot - Parse Colloquy bot/client terminal output
#
#   Copyright 2006 Nicola Worthington
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
############################################################

package Parse::Colloquy::Bot;
# vim:ts=4:sw=4:tw=78

use strict;
use Exporter;
use Carp qw(croak cluck confess carp);

use vars qw($VERSION $DEBUG @EXPORT @EXPORT_OK %EXPORT_TAGS @ISA);

$VERSION = '0.02' || sprintf('%d.%02d', q$Revision: 457 $ =~ /(\d+)/g);

@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(parse_line);
%EXPORT_TAGS = (all => \@EXPORT_OK);

$DEBUG = $ENV{DEBUG} ? 1 : 0;

BEGIN {
	# It would be nice to have high resolution times if possible
	eval { require Time::HiRes; import Time::HiRes qw(time); };
}

sub parse_line {
	my @out = ();
	for my $input (@_) {
		push @out, _parse_line($input);
	}
	if (wantarray) {
		return @out;
	} else {
		return $out[0] if @out == 1;
		return \@out;
	}
}

sub _parse_line {
	local $_ = $_[0];
	s/[\n\r]//g;
	s/^\s+|\s+$//g;

	my $raw = $_;
	$_ = "RAW $_" if m/^\+\+\+/;
	return unless m/^([A-Z]+\S*)(?:\s+(.+))?$/;

	my %args = (
			"time"    => time(),
			"raw"     => $raw,
			"msgtype" => $1 || '',
			"text"    => $2 || '',
			"args"    => [ split(/\s+/,$_||'') ],
			"command" => undef,
			"cmdargs" => undef,
			"list"    => undef,
			"person"  => undef,
			"respond" => undef,
		);
	local $_ = $args{text};

	if ($args{msgtype} =~ /^TALK|TELL$/ && /^(\S+)\s+[:>](.*)\s*$/) {
		TRACE('TALK|TELL');
		$args{person}  = $1;
		$args{text}    = $2;
		$args{args}    = [ split(/\s+/,$args{text}) ];
		$args{cmdargs} = [ @{$args{args}} ];
		$args{command} = shift @{$args{cmdargs}};

	} elsif ($args{msgtype} eq 'LISTINVITE' && /((\S+)\s+invites\s+you\s+to\s+(\S+)\s+To\s+respond,\s+type\s+(.+))\s*$/) {
		TRACE('LISTINVITE');
		$args{text}    = $1;
		$args{person}  = $2;
		$args{list}    = $3;
		$args{respond} = $4;
		$args{args}    = [ split(/\s+/,$args{text}) ];

	} elsif ($args{msgtype} eq 'LISTTALK' && /^(\S+)\s*%(.*)\s+{(.+?)}\s*$/) {
		TRACE('LISTTALK');
		$args{person}  = $1;
		$args{text}    = $2;
		$args{args}    = [ split(/\s+/,$args{text}) ];
		$args{cmdargs} = [ @{$args{args}} ];
		$args{command} = shift @{$args{cmdargs}};
		$args{list}    = '%'.$3;

	} elsif ($args{msgtype} eq 'LISTEMOTE' && /^%\s*(\S+)\s+(.*)\s+{(.+?)}\s*$/) {
		TRACE('LISTEMOTE');
		$args{person}  = $1;
		$args{text}    = $2;
		$args{args}    = [ split(/\s+/,$args{text}) ];
		$args{list}    = '%'.$3;

	} elsif ($args{msgtype} eq 'OBSERVED' && /^(\S+)\s+(\S+)\s+(\S+)\s+\@(.+)\s+{(\@.+?)}\s*$/) {
		TRACE("OBSERVED $2 (a)");
		$args{group}   = $args{list} = '@'.$1;
		$args{msgtype} = "OBSERVED $2";
		$args{person}  = $3;
		$args{text}    = $4;
		$args{args}    = [ split(/\s+/,$args{text}) ];
		$args{cmdargs} = [ @{$args{args}} ];
		$args{command} = shift @{$args{cmdargs}};

	} elsif ($args{msgtype} eq 'OBSERVED' && /^(\S+)\s+(\S+)\s+(?:\@\s+)(\S+)\s+(.+)\s+{(\@.+?)}\s*$/) {
		TRACE("OBSERVED $2 (b)");
		$args{group}   = $args{list} = '@'.$1;
		$args{msgtype} = "OBSERVED $2";
		$args{person}  = $3;
		$args{text}    = $4;
		$args{args}    = [ split(/\s+/,$args{text}) ];

	} elsif ($args{msgtype} eq 'OBSERVED' && /^(\S+)\s+GROUPCHANGE\s+(\S+)\s+(.*)\s*$/) {
		TRACE('OBSERVED GROUPCHANGE');
		$args{group}   = $args{list} = '@'.$1;
		$args{msgtype} = 'OBSERVED GROUPCHANGE';
		$args{person}  = $2;
		$args{text}    = $3;
		$args{args}    = [ split(/\s+/,$args{text}) ];

	} elsif ($args{msgtype} eq 'SHOUT' && /^(\S+)\s+\!(.*)\s*$/) {
		TRACE('SHOUT');
		$args{person}  = $1;
		$args{text}    = $2;
		$args{args}    = [ split(/\s+/,$args{text}) ];

	} elsif ($args{msgtype} eq 'CONNECT' && /^((\S+).+\s+(\S+)\.)\s*$/) {
		TRACE('CONNECT');
		$args{text}    = $1;
		$args{person}  = $2;
		$args{group}   = $args{list} = '@'.$3;
		$args{args}    = [ split(/\s+/,$args{text}) ];

	} elsif ($args{msgtype} eq 'IDLE' && /^((\S+)(.*))\s*$/) {
		TRACE('IDLE');
		$args{text}    = $1;
		$args{person}  = $2;
		$args{args}    = [ split(/\s+/,$args{text}) ];
	}

	DUMP('%args',\%args);
	return \%args;
}

sub TRACE {
	return unless $DEBUG;
	warn(shift());
}

sub DUMP {
	return unless $DEBUG;
	eval {
		require Data::Dumper;
		warn(shift().': '.Data::Dumper::Dumper(shift()));
	}
}

1;

=pod

=head1 NAME

Parse::Colloquy::Bot - Parse Colloquy bot/client terminal output

=head1 SYNOPSIS

 use strict;
 use Parse::Colloquy::Bot qw(:all);
 use Data::Dumper;
 
 # ... connect to Colloquy and read from the server ...
 my $parsed = parse_line($raw_input);
 print Dumper($parsed);  
 
=head1 DESCRIPTION

This module will parse the raw "client" or "bot" terminal line
output from a connection to a Colloquy server. 

=head1 FUNCTIONS

=head2 parse_line

Accepts a single scalar input line or an array of input. Will
return a hash reference or array of hash references for each
input line, depending on the context that the function called.

=head1 EXAMPLE

The following input line from Colloquy:

 LISTTALK neech2      %hello my name is neech {perl}

Will be parsed in to the following structure:

 $VAR1 = {
          'raw' => 'LISTTALK neech2      %hello my name is neech {perl}',
          'msgtype' => 'LISTTALK',
          'person' => 'neech2',
          'list' => '%perl'
          'text' => 'hello my name is neech',
          'args' => [
                      'hello',
                      'my',
                      'name',
                      'is',
                      'neech'
                    ],
          'command' => 'hello',
          'cmdargs' => [
                         'my',
                         'name',
                         'is',
                         'neech'
                       ],
          'respond' => undef,
          'time' => 1148224087,
        };

=head1 SEE ALSO

L<Colloquy::Data>, L<Colloquy::Bot::Simple>, L<Chatbot::TalkerBot>

=head1 VERSION

$Id: Bot.pm 483 2006-05-22 21:36:46Z nicolaw $

=head1 AUTHOR

Nicola Worthington <nicolaw@cpan.org>

L<http://perlgirl.org.uk>

=head1 COPYRIGHT

Copyright 2006 Nicola Worthington.

This software is licensed under The Apache Software License, Version 2.0.

L<http://www.apache.org/licenses/LICENSE-2.0>

=cut


__END__

