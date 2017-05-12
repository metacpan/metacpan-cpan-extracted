# BEGIN BPS TAGGED BLOCK {{{
# COPYRIGHT:
# 
# This software is Copyright (c) 2003-2008 Best Practical Solutions, LLC
#                                          <clkao@bestpractical.com>
# 
# (Except where explicitly superseded by other copyright notices)
# 
# 
# LICENSE:
# 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of either:
# 
#   a) Version 2 of the GNU General Public License.  You should have
#      received a copy of the GNU General Public License along with this
#      program.  If not, write to the Free Software Foundation, Inc., 51
#      Franklin Street, Fifth Floor, Boston, MA 02110-1301 or visit
#      their web page on the internet at
#      http://www.gnu.org/copyleft/gpl.html.
# 
#   b) Version 1 of Perl's "Artistic License".  You should have received
#      a copy of the Artistic License with this package, in the file
#      named "ARTISTIC".  The license is also available at
#      http://opensource.org/licenses/artistic-license.php.
# 
# This work is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# CONTRIBUTION SUBMISSION POLICY:
# 
# (The following paragraph is not intended to limit the rights granted
# to you to modify and distribute this software under the terms of the
# GNU General Public License and is only of importance to you if you
# choose to contribute your changes and enhancements to the community
# by submitting them to Best Practical Solutions, LLC.)
# 
# By intentionally submitting any modifications, corrections or
# derivatives to this work, or any other work intended for use with SVK,
# to Best Practical Solutions, LLC, you confirm that you are the
# copyright holder for those contributions and you grant Best Practical
# Solutions, LLC a nonexclusive, worldwide, irrevocable, royalty-free,
# perpetual, license to use, copy, create derivative works based on
# those contributions, and sublicense and distribute those contributions
# and any derivatives thereof.
# 
# END BPS TAGGED BLOCK }}}
package SVK::I18N;

use strict;
use base 'Exporter';

our @EXPORT = 'loc';

sub loc {
    no strict 'refs';
    local $SIG{__WARN__} = sub {};
    local $@;

    if ( !lang_is_english() && eval {
        require Locale::Maketext::Lexicon;
        require Locale::Maketext::Simple;
        Locale::Maketext::Simple->VERSION >= 0.13 &&
        Locale::Maketext::Lexicon->VERSION >= 0.42
    }) {
	Locale::Maketext::Simple->import(
	    Subclass    => '',
	    Path	    => substr(__FILE__, 0, -3),
	    Style	    => 'gettext',
	    Encoding    => 'locale',
	);
    }
    else {
	*loc = *_default_gettext;
    }

    goto &{"SVK::I18N::loc"};
}

sub _default_gettext {
    my $str = shift;
    $str =~ s{
	%			# leading symbol
	(?:			# either one of
	    \d+			#   a digit, like %1
	    |			#     or
	    (\w+|\*)\(		#   a function call -- 1
		(?:		#     either
		    %\d+	#	an interpolation
		    |		#     or
		    ([^,]*)	#	some string -- 2
		)		#     end either
		(?:		#     maybe followed
		    ,		#       by a comma
		    ([^),]*)	#       and a param -- 3
		)?		#     end maybe
		(?:		#     maybe followed
		    ,		#       by another comma
		    ([^),]*)	#       and a param -- 4
		)?		#     end maybe
		[^)]*		#     and other ignorable params
	    \)			#   closing function call
	)			# closing either one of
    }{
	my $digit = $2 || shift;
	$digit . (
	    $1 ? (
		($1 eq 'tense') ? (($3 eq 'present') ? 'ing' : 'ed') :
		($1 eq 'quant' || $1 eq '*') ? ' ' . (($digit > 1) ? ($4 || "$3s") : $3) :
		''
	    ) : ''
	);
    }egx;
    return $str;
}

# try to determine if the locale is English.  This might yield a false
# negative in some corner cases, but then Locale::Maketext::Simple
# will do a more thorough analysis.  This is just an optimization.
sub lang_is_english {
    for my $env_name (qw( LANGUAGE LC_ALL LC_MESSAGES LANG )) {
        next if !$ENV{$env_name};
        return 1 if $ENV{$env_name} =~ /^en/;
        return;
    }

    return;
}

1;
