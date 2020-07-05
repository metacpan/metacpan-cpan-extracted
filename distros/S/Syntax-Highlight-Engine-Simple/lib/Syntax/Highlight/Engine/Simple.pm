package Syntax::Highlight::Engine::Simple;
use warnings;
use strict;
use Carp;
our $VERSION = '0.102';

    ### ---
    ### constructor
    ### ---
    sub new {
        
        my $class = shift;
        my $self = bless {type => undef, syntax  => undef, @_}, $class;
        
        $self->setParams(@_);
        
        if ($self->{type}) {
            
            my $class = "Syntax::Highlight::Engine::Simple::". $self->{type};
            
            require $class;
            $class->setSyntax();
            
            return $self;
        }
        
        $self->setSyntax();
        
        return $self;
    }
    
    ### ---
    ### set params
    ### ---
    sub setParams {
        
        my $self = shift;
        
        my %args = (
            html_escape_code_ref => \&_html_escape,
            @_);
    
        $self->{html_escape_code_ref} = $args{html_escape_code_ref};
    }
    
    ### ---
    ### set syntax
    ### ---
    sub setSyntax {
        
        my $self = shift;
        my %args = (syntax => [], @_);
        
        $self->{syntax} = $args{syntax};
    }
    
    ### ---
    ### append syntax
    ### ---
    sub appendSyntax {
        
        my $self = shift;
        my %args = (
            syntax => {
                regexp      => '',
                class       => '',
                container   => undef,
            }, @_);
        
        push(@{$self->{syntax}}, $args{syntax});
    }
    
    ### ---
    ### Highlight multi Line
    ### ---
    sub doStr{
        
        my $self = shift;
        my %args = (str => '', tab_width => -1, @_);
        
        defined $args{str} or croak 'doStr method got undefined value';
        
        if ($args{tab_width} > 0) {
            
            my $tabed = '';
            
            foreach my $line (split(/\r\n|\r|\n/, $args{str})) {
                
                $tabed .=
                    &_tab2space($line, $args{tab_width}). "\n";
            }
            
            $args{str} = $tabed;
        }
        
        return $self->_doLine($args{str});
    }
    
    ### ---
    ### Highlight file
    ### ---
    sub doFile {
        
        my $self = shift;
        my %args = (
            file => '',
            tab_width => -1,
            encode => 'utf8',
            @_);
        
        my $str = '';
        
        require 5.005;
        
        open(my $filehandle, '<'. $args{file}) or croak 'File open failed';
        binmode($filehandle, ":encoding($args{encode})");
        
        while (my $line = <$filehandle>) {
            if ($args{tab_width} > 0) {
                $line = &_tab2space($line, $args{tab_width});
            }
            $str .= $line;
        }
        
        close($filehandle);
        
        return $self->_doLine($str);
    }
    
    ### ---
    ### Highlight single line
    ### ---
    sub _doLine {
        
        my ($self, $str) = @_;
        
        $str =~ s/\r\n|\r/\n/g;
        
        $self->{_markup_map} = [];
        
        ### make markup map
        foreach my $i (0 .. $#{$self->{syntax}}) {
            $self->_makeAllowHash($i);
            $self->_make_map($str, $i);
        }
    
        my $outstr = '';
        my $last_pos = 0;
        
        ### Apply the map to string
        foreach my $pos ($self->_restracture_map()) {
            
            my $str_left = substr($str, $last_pos, $$pos[0] - $last_pos);
            
            $outstr .= $self->{html_escape_code_ref}->($str_left);
            
            if (defined $$pos[1]) {
                $outstr .= sprintf("<span class='%s'>", $$pos[1]->{class});
            } else {
                $outstr .= '</span>';
            }
            $last_pos = $$pos[0];
        }
        
        return $outstr. $self->{html_escape_code_ref}->(substr($str, $last_pos));
    }
    
    ### ---
    ### Prepare hash for container matching
    ### ---
    sub _makeAllowHash {
        
        my $self = shift;
        
        if (! exists $self->{syntax}->[$_[0]]->{container} ) {
            return;
        }
        
        my $allowed = $self->{syntax}->[$_[0]]->{container};
        
        if (ref $allowed eq 'ARRAY') {
            foreach my $class ( @$allowed ) {
                $self->{syntax}->[$_[0]]->{_cont_hash}->{$class} = 0;
            }
        } elsif ($allowed) {
            $self->{syntax}->[$_[0]]->{_cont_hash}->{$allowed} = 0;
        }
    }
    
    ### ---
    ### Make markup map
    ### ---------------------------------------
    ### | open_pos  | close_pos | syntax index
    ### | open_pos  | close_pos | syntax index
    ### | open_pos  | close_pos | syntax index
    ### ---------------------------------------
    ### ---
    sub _make_map {
        
        no warnings; ### Avoid Deep Recursion warning
        
        my ($self, $str, $index, $pos) = @_;
        $pos ||= 0;
        
        my $map_ref = $self->{_markup_map};
        
        my @scraps =
            split(/$self->{syntax}->[$index]->{regexp}/, $str, 2);
    
        if ((scalar @scraps) >= 2) {
            
            my $rest = pop(@scraps);
            my $ins_pos0 = $pos + length($scraps[0]);
            my $ins_pos1 = $pos + (length($str) - length($rest));
            
            ### Add markup position
            push(@$map_ref, [
                    $ins_pos0,
                    $ins_pos1,
                    $index,
                ]
            );
            
            ### Recurseion for rest
            $self->_make_map($rest, $index, $ins_pos1);
        }
        
        ### Follow up process
        elsif (@$map_ref) {
            
            @$map_ref = sort {
                    $$a[0] <=> $$b[0] or
                    $$b[1] <=> $$a[1] or
                    $$a[2] <=> $$b[2]
                } @$map_ref;
        }
    
        return;
    }
    
    ### ---
    ### restracture the map data into following format
    ### ------------------------
    ### | open_pos  | syntax ref
    ### | close_pos |       
    ### | open_pos  | syntax ref
    ### | close_pos |       
    ### ------------------------
    ### ---
    sub _restracture_map {
        
        my $self = shift;
        my $map_ref = $self->{_markup_map};
        my @out_array;
        my @root = ();
        
        REGLOOP: for (my $i = 0; $i < scalar @$map_ref; $i++) {
            
            ### vacuum @root
            for (my $j = 0; $j < scalar @root; $j++) {
                if ($root[$j]->[1] <= $$map_ref[$i]->[0]) {
                    splice(@root, $j--, 1);
                }
            }
    
            my $syntax_ref = $self->{syntax}->[$$map_ref[$i]->[2]];
            my $ok = 0;
            
            ### no container restriction
            if (! exists $$syntax_ref{container}) {
                if (!scalar @root) {
                    $ok = 1;
                }
            } else {
                
                ### Search for container
                BACKWARD: for (my $j = scalar @root - 1;  $j >= 0; $j--) {
                    
                    ### overlap?
                    if ($root[$j]->[1] > $$map_ref[$i]->[0]) {
                        
                        ### contained?
                        if ($root[$j]->[1] >= $$map_ref[$i]->[1]) {
                            
                            my $root_class =
                                $self->{syntax}->[$root[$j]->[2]]->{class};
                            
                            if (exists $$syntax_ref{_cont_hash}->{$root_class}) {
                                $ok = 1; last BACKWARD; # allowed
                            }
                            last BACKWARD; # container not allowed
                        }
                        last BACKWARD; # illigal overlap
                    }
                    splice(@root, $j, 1);
                }
            }
            
            if (! $ok) {
                splice(@$map_ref, $i--, 1);
                next REGLOOP;
            }
            
            push(@root, $$map_ref[$i]);
            
            push(
                @out_array,
                [$$map_ref[$i]->[0], $syntax_ref],
                [$$map_ref[$i]->[1]]
            );
        }
        @out_array = sort {$$a[0] <=> $$b[0]} @out_array;
        return @out_array;
    }
    
    ### ---
    ### replace tabs to spaces
    ### ---
    sub _tab2space {
        
        no warnings 'recursion';
        
        my ($str, $width) = @_;
        $str ||= '';
        $width = defined $width ? $width : 4;
        my @scraps = split(/\t/, $str, 2);
        
        if (scalar @scraps == 2) {
            
            my $num = $width - (length($scraps[0]) % $width);
            my $right_str = &_tab2space($scraps[1], $width);
            
            return ($scraps[0]. ' ' x $num. $right_str);
        }
        
        return $str;
    }
    
    ### ---
    ### convert array to regexp
    ### ---
    sub array2regexp {
        
        my $self = shift;
        
        return sprintf('\\b(?:%s)\\b', join('|', @_));
    }
    
    ### ---
    ### Return Class names 
    ### ---
    sub getClassNames {
        
        return map {${$_}{class}} @{shift->{syntax}}
    }
    
    ### ---
    ### HTML escape
    ### ---
    sub _html_escape {
        
        my ($str) = @_;
        
        $str =~ s/&/&amp;/g;
        $str =~ s/</&lt;/g;
        $str =~ s/>/&gt;/g;
        
        return $str;
    }

1;

__END__

=head1 NAME

Syntax::Highlight::Engine::Simple - Simple Syntax Highlight Engine

=head1 VERSION

This document describes Syntax::Highlight::Engine::Simple

=head1 SYNOPSIS

    use Syntax::Highlight::Engine::Simple;
    
    # Constractor
    $highlight = Syntax::Highlight::Engine::Simple->new(%hash);
    
    # Parameter configuration
    $highlight->setParams(%hash);
    
    # Syntax definision and addition
    $highlight->setSyntax(%hash);
    $highlight->appendSyntax(%hash);
    
    # Perse
    $highlight->doFile(%hash);
    $highlight->doStr(%hash);
    
    # Utilities
    $highlight->array2regexp(%hash);
    $highlight->getClassNames(%hash);

=head1 DESCRIPTION

This is a Syntax highlight Engine. This generates a part of HTML string by
marking up the input string with span tags along the given rules so that you
can easily coloring with CSS.

Advantage is the simpleness. This provides a simple way to define the
highlighting rules by packing the complicated part of it into regular
expression. Also, This works faster than similar highlight solutions on rough
benchmarks.

Here is a working example of This module.

http://jamadam.com/dev/cpan/demo/Syntax/Highlight/Engine/Simple/

=head1 INTERFACE 

=head2 new

I<new> constractor calls for following arguments.

=over

B<type>

File type. This argument causes specific sub class to be loaded.

B<syntax>

With this argument, you can assign rules in constractor.

=back

=head2 setParams

This method calls for following arguments.

=over

B<html_escape_code_ref>

HTML escape code ref. Default subroutine escapes 3 characters '&', '<' and '>'.

=back

=head2 setSyntax

Set the rules for highlight. It calls for a argument I<syntax> in array.

    $highlighter->setSyntax(
        syntax => [
                {
                    class => 'tag',
                    regexp => "<.+?>",
                },
                {
                    class => 'quote',
                    regexp => "'.*?'",
                    container => 'tag',
                },
                {
                    class => 'wquote',
                    regexp => '".*?"',
                    container => 'tag',
                },
                {
                    class => 'keyword',
                    regexp => 'somekeyword',
                    container => ['tag', 'quote', 'wquote'],
                },
        ]
    );

The array can contain rules in hash which is consists of 3 keys, I<class>,
I<regexp> and I<container>.

=over

B<class>

This appears to the output SPAN tag. 

B<regexp>

Regular expression to be highlighted.

B<container>

Class names of allowed container. It can be given in String or Array. This
restricts the I<regexp> to stand only inside of the classes. This parameter
also works to ease the regulation some time. The highlighting rules doesn't
stand in any container in default. This parameter eliminates it.

=back

=head2 appendSyntax

Append syntax by giving a hash.

    $highlighter->setSyntax(
        syntax => {
            class       => 'quote',
            regexp      => "'.*?'",
            container   => 'tag',
        }
    );

=head2 doStr

Highlighting input string and returns the marked up string. This method calls
for following arguments.

=over

B<str>

String.

B<tab_width>

Tab width for tab-space conversion. -1 for disable it. -1 is the default.

=back

    $highlighter->doStr(
        str         => $str,
        tab_width   => 4
    );

=head2 doFile

Highlighting the file and returns the marked up string. This method calls for
following arguments.

=over

B<file>

File name.

B<tab_width>

Tab width for tab-space conversion. -1 for disable it. -1 is the default.

B<encode>

Set the encode of file. utf8 is the default.

=back

    $highlighter->doStr(
        str         => $str,
        tab_width   => 4,
        encode      => 'utf8'
    );

=head2 array2regexp

This is a utility method for converting string array to regular expression.

=over

=back

=head2 getClassNames

Returns the class names in array.

=over

=back

=head1 DIAGNOSTICS

=over

=item C<< doStr method got undefined value >>

=item C<< File open failed >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

I<Syntax::Highlight::Engine::Simple> requires no configuration files or
environment variables. Specific language syntax can be defined with
sub classes and loaded in constructor if you give it the type argument.

=head1 DEPENDENCIES

=over

=item L<UNIVERSAL::require>

=item L<encoding>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-syntax-highlight-engine-Simple@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.

=head1 SEE ALSO

=over

=item L<Syntax::Highlight::Engine::Simple::HTML>

=item L<Syntax::Highlight::Engine::Simple::Perl>

=back

=head1 AUTHOR

Sugama Keita  C<< <sugama@jamadam.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Sugama Keita C<< <sugama@jamadam.com> >>. All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See I<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
