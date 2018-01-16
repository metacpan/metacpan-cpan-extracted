package PowerBuilder::DataWindow;

use strict;
use warnings;# FATAL => 'all';

use feature 'say';
use File::Slurp qw(slurp read_file);
use MarpaX::Languages::PowerBuilder::SRD;
use Data::Dumper::GUI;

my $_debug;
sub DEBUG { $_debug; }

sub new {
	my $class = shift;
    my %params = @_; 
    
    my $self = {};
    if (%params){
        $_debug = $params{DEBUG};
    }
    
    return bless $self, $class;
}

$| = 1;

sub parse {
	my $self = shift;
    my $input = shift;
	
    #3 ways to pass input: glob, file-name, full-string
    if(ref $input eq 'GLOB'){
        $input = do{ local $/; <$input> };
    }
    elsif($input !~ /\n/ && -f $input){	#do not use -f directly or it will show a warning when given the DW content : Unsuccessful stat on filename containing newline
        $input = slurp $input;
    }    
    
    my $parser = MarpaX::Languages::PowerBuilder::SRD->new->parse($input);
	if($parser->{error}){
    	die $parser->{error};
	}
    my $parsed = $parser->{recce}->value();
    Dumper(${$parsed}) if DEBUG;
    $self->{parsed} = ${$parsed};
    
    $self->{sele} = ();
    my $select = ${$parsed}->{table}->{retrieve};
	if($select){
    	if($select =~ /PBSELECT/){
            use MarpaX::Languages::PowerBuilder::SRQ;
            my $PBparser = MarpaX::Languages::PowerBuilder::SRQ->new->parse_inline_query($select);
            $select = $PBparser->sql();
            say "converted select = $select" if DEBUG;
        }
        say "select = $select" if DEBUG;
        $self->{select} = $select;
    
    
    #========= This sections needs rewriting in order to get properly the columns ===================
    
        #get the selected columns
    #    my $j=1;
    #    foreach ($select =~ /([\w_\d]+)\s*(?:,|FROM)/g){
    #        $self->{sele}{lc $_} = $j;
    ##        s/t[^_]+_//g;
    ##        $self->{sele}{lc $_} = $j;
    #        $j++;
    #	}

        my $sel_cols;
        my @sel_lines = split(/\n/, $select);
        foreach (@sel_lines){
            if (/^\s*SELECT/i .. /\s*FROM\s+/i){
                chomp;
#                say " one column: $_" if DEBUG;
                $sel_cols .= $_;
                #~ if(/^((?:\w|.|")+),$/){
                    #~ $sele{$1} = $j;
                    #~ $j++;
                #~ }
            }
        }
        $sel_cols =~ s/~"//g;			#clean escaped quotes
        $sel_cols =~ s/[\w_\d]+\.//g;	#clean owner prefix

        #get the selected columns
        my $j=1;
        foreach ($sel_cols =~ /(?:SELECT)?\s*([\w_\d]+)\s*(?:,|FROM)?/ig){
            say " one column: $_" if DEBUG;
            $self->{sele}{lc $_} = $j;
    #        s/t[^_]+_//g;
    #        $sele{lc $_} = $j;
            $j++;
        }
        
        #============================================================================
        
    }

#	Dumper(${$parsed}->{columns});
#	$self->{controls} = ${$parsed}->{controls};
    
#    $self->{datacolumns} = ${$parsed}->{table}{columns};
    
#    $self->{dw_properties} = ${$parsed}->{datawindow};
}

sub select {
	my $self = shift;
    return $self->{select};
}

sub select_columns {
	my $self = shift;
	return $self->{sele};
}

sub controls {
	my $self = shift;
    my $type = shift;
    return [ grep { $_->{type} =~ /$type/ } values %{$self->{parsed}->{controls}} ];
}

sub column_controls {
	my $self = shift;
    return $self->controls("column");
}

sub text_controls {
	my $self = shift;
    return $self->controls("text");
}

sub column_definitions {
	my $self = shift;
    $DB::single=1;
    return $self->{parsed}->{table}->{columns};
}

sub properties {
	my $self = shift;
    return $self->{parsed}->{datawindow};
}


=encoding utf8

=head1 NAME

PowerBuilder::DataWindow - PoweBuilder datawindows helpers and diagnostics in Perl, based on MarpaX::Languages::Powerbuilder Marpa parsers

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use PowerBuilder::DataWindow;

    my $foo = PowerBuilder::DataWindow->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

=head2 function2

=cut

=head1 AUTHOR

Sébastien Kirche, C<< <sebastien.kirche at free.fr> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at 
L<http://github.com/sebkirche/PowerBuilder-DataWindow/issues>.  
I will be notified, and then you'll automatically be notified of progress on 
your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PowerBuilder::DataWindow


You can also look for information at:

=over 4

=item * Git repository

L<http://github.com/sebkirche/PowerBuilder-DataWindow>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Sébastien Kirche.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license. 

L<The MIT License (MIT)>

Copyright (c) 2014 Sébastien Kirche

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=cut

1; # End of PowerBuilder::DataWindow
