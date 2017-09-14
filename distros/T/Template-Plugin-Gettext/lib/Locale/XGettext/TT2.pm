#! /bin/false

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

package Locale::XGettext::TT2;

use strict;

use Locale::TextDomain qw(Template-Plugin-Gettext);
use Template;

use base qw(Locale::XGettext);

sub versionInformation {
    return __x('{program} (Template-Plugin-Gettext) {version}
Copyright (C) {years} Cantanea EOOD (http://www.cantanea.com/).
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Written by Guido Flohr (http://www.guido-flohr.net/).
',
    program => $0, years => '2016-2017', 
    version => $Locale::XGettext::VERSION);
}

sub fileInformation {
    return __(<<EOF);
Input files are interpreted as plain text files with each paragraph being
a separately translatable unit.  
EOF
}

sub canExtractAll {
    shift;
}

sub canKeywords {
    shift;
}

sub defaultKeywords {
    return [
               'gettext:1',
               'ngettext:1,2',
               'pgettext:1c,2',
               'gettextp:1,2c',
               'npgettext:1c,2,3',
               'ngettextp:1,2,3c',
               'xgettext:1',
               'nxgettext:1,2',
               'pxgettext:1c,2',
               'xgettextp:1,2c',
               'npxgettext:1c,2,3',
               'nxgettextp:1,2,3c',
       ];
}

sub defaultFlags {
    return [
               "xgettext:1:perl-brace-format",
               "nxgettext:1:perl-brace-format",
               "nxgettext:2:perl-brace-format",
               "pxgettext:2:perl-brace-format",
               "xgettextp:1:perl-brace-format",
               "npxgettext:2:perl-brace-format",
               "npxgettext:3:perl-brace-format",
               "nxgettextp:1:perl-brace-format",
               "nxgettextp:2:perl-brace-format",
    ];
}

sub readFile {
    my ($self, $filename) = @_;

    my %options = (
        RELATIVE => 1
    );

    my $parser = Locale::XGettext::TT2::Parser->new(\%options);
    
    my $tt = Template->new({
        %options,
        PARSER => $parser,
    });
 
    my $sink;
    $parser->{__xgettext} = $self;
    $parser->{__xgettext_filename} = $filename;
    
    $tt->process($filename, {}, \$sink) or die $tt->error;

    return $self;
}

package Locale::XGettext::TT2::Parser;

use strict;

use Locale::TextDomain qw(Template-Plugin-Gettext);

use base qw(Template::Parser);

sub split_text {
    my ($self, $text) = @_;

    my $chunks = $self->SUPER::split_text($text) or return;

    my $keywords = $self->{__xgettext}->keywords;
    
    my $ident;
    while (my $chunk = shift @$chunks) {
        if (!ref $chunk) {
            shift @$chunks;
            next;
        }
        
        my ($text, $lineno, $tokens) = @$chunk;

        next if !ref $tokens;

        if ('USE' eq $tokens->[0] && 'IDENT' eq $tokens->[2]) {
            if ('Gettext' eq $tokens->[3]
                && (4 == @$tokens
                    || '(' eq $tokens->[4])) {
                $ident = 'Gettext';
            } elsif ('ASSIGN' eq $tokens->[4] && 'IDENT' eq $tokens->[6]
                     && 'Gettext' eq $tokens->[7]) {
                $ident = $tokens->[3];
            }
            next;
        }

        next if !defined $ident;

        if ('IDENT' eq $tokens->[0] && $ident eq $tokens->[1]
            && 'DOT' eq $tokens->[2] && 'IDENT' eq $tokens->[4]
            && exists $keywords->{$tokens->[5]}) {
            my $keyword = $keywords->{$tokens->[5]};
            $self->__extractEntry($text, $lineno, $keyword, 
                                  @$tokens[6 .. $#$tokens]);
        } else {
            for (my $i = 0; $i < @$tokens; $i += 2) {
                if ('FILTER' eq $tokens->[$i]
                    && 'IDENT' eq $tokens->[$i + 2]
                    && exists $keywords->{$tokens->[$i + 3]}
                    && '(' eq $tokens->[$i + 4]) {
                    my @tokens;
                    my $keyword = $keywords->{$tokens->[$i + 3]};
                    # Inject the block contents as the first argument.
                    if ($i) {
                        my $first_arg;
                        if ($tokens->[$i - 2] eq 'LITERAL') {
                            $first_arg = $tokens->[$i - 1];
                        } else {
                            next;
                        }
                        splice @$tokens, 6 + $i, 0, 
                               'LITERAL', $first_arg, 'COMMA', ',';
                    } else {
                        next if !@$chunks;
                        my $first_arg;
                        if (ref $chunks->[0]) {
                            next if $chunks->[0]->[2] ne 'ITEXT';
                            $first_arg = $chunks->[0]->[0];
                        } elsif ('TEXT' eq $chunks->[0]) {
                            $first_arg = $chunks->[1];
                        } else {
                            next;
                        }
                        splice @$tokens, 6, 0, 
                               'LITERAL', $first_arg, 'COMMA', ',';
                    }
                    $self->__extractEntry($text, $lineno, $keyword,
                                          @$tokens[$i + 4 .. $#$tokens]);
                }
            }
        }
    }

    # Stop processing here, so that for example includes are ignored.    
    return [];
}

sub __extractEntry {
    my ($self, $text, $lineno, $keyword, @tokens) = @_;
    
    my $args = sub {
        my (@tokens) = @_;
        
        return if '(' ne $tokens[0];

        splice @tokens, 0, 2;
        
        my @values;
        while (@tokens) {
            if ('LITERAL' eq $tokens[0]) {
                my $string = substr $tokens[1], 1, -1;
                $string =~ s/\\([\\'])/$1/gs;
                push @values, $string;
                splice @tokens, 0, 2;
            } elsif ('"' eq $tokens[0]) {
                if ('TEXT' eq $tokens[2]
                    && '"' eq $tokens[4]
                    && ('COMMA' eq $tokens[6]
                        || ')' eq $tokens[6])) {
                    push @values, $tokens[3];
                    splice @tokens, 6;    
                } else {
                      # String containing interpolated variables.
                    my $msg = __"Illegal variable interpolation at \"\$\"!";
                    push @values, \$msg;
                    while (@tokens) {
                        last if 'COMMA' eq $tokens[0];
                        last if ')' eq $tokens[0];     
                        shift @tokens;             
                    }
                }
            } elsif ('NUMBER' eq $tokens[0]) {
                push @values, $tokens[1];
                splice @tokens, 0, 2;
            } elsif ('IDENT' eq $tokens[0]) {
                # We store undef as the value because we cannot use it
                # anyway.
                push @values, undef;
                splice @tokens, 0, 2;
            } elsif ('(' eq $tokens[0]) {
                splice @tokens, 0, 2;
                my $nested = 1;
                while (@tokens) {
                    if ('(' eq $tokens[0]) {
                        ++$nested;
                        splice @tokens, 0, 2;
                    } elsif (')' eq $tokens[0]) {
                        --$nested;
                        splice @tokens, 0, 2;
                        if (!$nested) {
                            push @values, undef;
                            last;
                        }
                    } else {
                        splice @tokens, 0, 2;
                    }
                }
            } else {
                return @values;
            }
            
            return @values if !@tokens;

            my $next = shift @tokens;
            if ('COMMA' eq $next) {
                shift @tokens;
                next;
            } elsif ('ASSIGN' eq $next && '=>' eq $tokens[0]) {
                shift @tokens;
                next;
            }

            return @values;
        }
                    
        return @values;
    };
    
    my $min_args = $keyword->singular; 
    my %forms = (msgid => $keyword->singular);
    if ($keyword->plural) {
        $min_args = $keyword->plural if $keyword->plural > $min_args;
        $forms{msgid_plural} = $keyword->plural;
    }

    if ($keyword->context) {
        $min_args = $keyword->context if $keyword->context > $min_args;
        $forms{msgctxt} = $keyword->context;
    }

    my @args = $args->(@tokens);
             
    # Do we have enough arguments?
    return if $min_args > @args;

    my $entry = {
        keyword => $keyword->{function}
    };
    foreach my $prop (keys %forms) {
        my $argno = $forms{$prop} - 1;
                 
        # We are only interested in literal values.  Whatever is
        # undefined is not parsable or not valid.
        return if !defined $args[$argno];
        if (ref $args[$argno]) {
            my $filename = $self->{__xgettext_filename};
            die "$filename:$lineno: ${$args[$argno]}\n" if ref $args[$argno];
        }
        $entry->{$prop} = $args[$argno];
    }
             
    my $reference = $self->{__xgettext_filename} . ':' . $lineno;
    $reference =~ s/-[1-9][0-9]*$//;
    $entry->{reference} = $reference;
    
    if ($text =~ /^#/) {
        my $comment = '';
        my @lines = split /\n/, $text;
        foreach my $line (@lines) {
            last if $line !~ s/^[ \t\r\f\013]*#[ \t\r\f\013]?//;
                            
            $comment .= $line . "\n";
        }
        $entry->{automatic} = $comment;
    }

    $self->{__xgettext}->addEntry($entry);
    
    return $self;
}

1;
