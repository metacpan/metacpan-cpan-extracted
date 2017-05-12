package Pod::Simple::Select;
use strict;
use warnings;

=head1 NAME

Pod::Simple::Select - Select parts in a file using pod directives

=head1 VERSION

Version 0.001

=cut

our $VERSION = '0.001';

use base qw(Pod::Simple);
use Fcntl 'O_RDONLY';
use Tie::File;

#use Carp qw/confess/;
use Log::Log4perl;
use Data::Dumper;

my $end_line;
my $key;
my $h_value;
#my $token_match;
my $token;

#my $last_end;

my $conf = q(
    log4perl.rootLogger=ERROR, LOGFILE1, Screen
   #log4perl.rootLogger=DEBUG, LOGFILE1, Screen
   #log4perl.logger.Pod.Simple.Select=DEBUG, LOGFILE1, Screen
   #log4perl.logger.Pod.Simple.Select.Token=DEBUG, LOGFILE1, Screen
    log4perl.appender.LOGFILE1=Log::Log4perl::Appender::File
    log4perl.appender.LOGFILE1.filename=./debug.log
    log4perl.appender.LOGFILE1.mode=clobber
    log4perl.appender.LOGFILE1.layout=PatternLayout
    log4perl.appender.LOGFILE1.Threshold=DEBUG
    log4perl.appender.LOGFILE1.layout.ConversionPattern= %c{1}-%M{1} %m%n

    log4perl.appender.Screen=Log::Dispatch::Screen
    log4perl.appender.Screen.stderr=0
    log4perl.appender.Screen.Threshold=DEBUG
    log4perl.appender.Screen.mode=append
    log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern=%c{1}-%M{1} %m%n
 );
Log::Log4perl->init( \$conf );

=head1 SYNOPSIS

  use Pod::Simple::Select;

  my $p = Pod::Simple::Select->new;
  $p->output_file("out");
  $p->select(["head1" =>["Top1"=>["head2"=>["Top12"]]], "head2" =>["Function doit"], "head3"=>["Top3"]]);
  $p->parse_file(ex.pod);

Given that the ex.pod file is

    =head1 NotFound

    Bla
    Bla
    Bla

    =head1 NotFound

    Bla
    Bla
    Bla

    =head1 Top1

    Bla under top1
    Bla2 under top1
    Bla3 under top1

    =head2 Top12

    Bla under top12
    Bla2 under top12
    Bla3 under top12

    =cut

    code
    code 
    code

    =head2 Function C<Doit>

    Bla under Function Doit
    Bla2 under Function Doit
    Bla3 under Function Doit

    =head2 Top12

    Bla under top12_2
    Bla2 under top12_2
    Bla3 under top12_2

    =head1 NotFound

    Bla
    Bla
    Bla

    =head3 Top3

    Bla under top3

    =head1 NotFound

    Bla
    Bla
    Bla

The out file will be

    =head2 Top12

    Bla under top12
    Bla2 under top12
    Bla3 under top12

    =head2 Function C<Doit>

    Bla under Function Doit
    Bla2 under Function Doit
    Bla3 under Function Doit

    =head3 Top3

    Bla under top3

=head1 DESCRIPTION


This module will extract specified sections of
pod documentation from a file. This ability is provided by the
B<select> method which arguments specify the set of
POD sections to select for processing/printing.

=head1 SECTION SPECIFICATIONS

The argument to C<select> may be given as a hash or an array refence.
An array reference containing array refereces will restrict the text processed to only the
desired set of sections, or subsections following a section. 

Pod directive is head1, head2 and so on.

The formal syntax of a section specification is:

=over 4

=item * Ordered parsing

 ["Pod directive" =>["Text following the directive"=>["Pod directive 2"=>["Text2"]], "Text3], "Pod directive 3" => [Text4], ...]

A list of token will be made using these array references and that list will be used for the parsing. 
A key (:text after a pod directive) not found in the file will stop the parser from searching further down. 
If an array references are enclosed within each other, the parsing will search for a sequence in the same order.

=item * Unordered parsing

 {"Pod directive" =>["Text following the directive", "Text2", "Text3], "Another pod directive => [Text4], ...}

A list of token is constructed during the parsing, and all the Pod directive and key are on the same level. 
The order in the hash has no meaning. A pod directive or a key given in the hash and not found in the file won't stop the parsing.

=back

=cut

sub new {
    my $self = shift;
    my $new  = $self->SUPER::new(@_);
    $new->{log} = Log::Log4perl->get_logger(__PACKAGE__);

    #$new->cut_handler( \&cut_seen );
    $new->{output_as_hash} = 0;
    return $new;

}

=head1 B<select()>

    $parser->select(["head1"=>["select()", "output_hash"]]);

    $parser->select({head1 =>["select()", "output_hash"]});

The first call will search for the pod section in that order.
The second call will catch the two section in any order.

    $parser->select(["head1" => ["select()", ["head1"=>["output_hash()"]]]]);

This will search for a C<<=head1 B<output_hash()> >> pod secttion following a C<< =head1 B<select()> >> section.

=cut

sub select {
    my ( $self, $ar_r ) = @_;
    if ( ref $ar_r eq "ARRAY" ) {
        $self->make_tree( undef, undef, $ar_r );

        #add a last token as a sentinelle so that the
        #whole file is parse and the last line of
        #the last token to fetch is found correctly
        Pod::Simple::Select::Token->new( $self->{doc}, "Document_end" );
        my $next = $self->{doc}->child_at(0);
        $self->link_tree( $self->{doc}, $next ) if ($next);
        $self->cut_handler( \&cut_seen );
    }
    elsif ( ref $ar_r eq "HASH" ) {

        my @pods;
        my @keys_r;
        for my $key ( keys %$ar_r ) {
            push @pods, $key;
            my $k_r = $ar_r->{$key};
            my @k_p;
            for my $key (@$k_r) {
                push @k_p, qr/\b$key\b/i;
            }
            push @keys_r, \@k_p;

        }
        $self->{doc} = Pod::Simple::Select::Token->new( undef, "doc" );
        $self->{doc}->set_pod_pattern( \@pods );
        $self->{doc}->{key_pat} = \@keys_r;
        $self->cut_handler( \&cut_seen_uo );

        {
            no warnings "redefine";

            *_handle_element_start = \&_handle_element_start_uo;
            *_handle_text          = \&_handle_text_uo;

        }
    }
}

#A recursive method for creating a list of token using the array ref given in select
#param: $token the parent token,
#       $pod_dir the directive given in array ref for the token
#       $ar_r the array ref from select
#Use the parent child relation

sub make_tree {
    my ( $self, $token, $pod_dir, $ar_r ) = @_;
    my $child_token;
    if ( !defined $token ) {
        $token = Pod::Simple::Select::Token->new( undef, "doc" );
        $self->{doc} = $token;
    }
    my $pod_sel;
    for my $val ( @{$ar_r} ) {
        if ( ref $val eq "ARRAY" ) {
            for my $key (@$val) {
                if ( ref $key eq "ARRAY" ) {
                    $self->make_tree( $child_token, $pod_sel, $key );
                }
                else {
                    #print "make_tree 3 ", $key, "\n";
                    $child_token =
                        Pod::Simple::Select::Token->new( $token, $pod_sel );
                    $child_token->set_key($key);
                    #print $child_token->get_level, "\n";
                }
            }    #for
        }    #if
        else {
            $pod_sel = $val;
        }
    }    #for
}

#A recursive method for creating a list of token using the array ref given in select
#param: $parent the parent token,
#       $first_child
#Create the next and previous relations. 
#a parent's next is the first child
#a child's next is it's brother (or sister ... it's parent's next child)
#The last child is the parent's brother :
#that is: the next token of a leaf child is its neigbhour or the the parent neighbour
#In ->select the last token received a sentinelle token with pod dir "end_document" 
#so that the parsing can terminate with undefined token

sub link_tree {
    my ( $self, $parent, $first_child ) = @_;
    return unless $first_child;
    $self->{log}->debug(
        "link_tree previous: ", $parent->get_key,
        " next: ",          $first_child->get_key
    );
    $parent->next($first_child);
    $first_child->previous($parent);
    my $next;
    for my $t ( $parent->children ) {
        if ( $t->children_count ) {
            $self->{log}->debug( $t->get_key, " has ", $t->children_count,
                " children" );
            $next = $t->child_at(0);
        }
        else {
            $next = $parent->child_at( $t->next_index );
        }
        $self->link_tree( $t, $next );
    }
}

#For debugging: print the tree of token

sub print_tree {
    my $self  = shift;
    my $token = $self->{doc};
    my $last;
    print "print_tree\n";
    if ( ref $token->{pod_pat} eq "Regexp" ) {
        print $token->{pod_pat};
        return;
    }
    while ($token) {
        my $pat = $token->get_key_pattern;
        print "\t" x $token->get_level, " ";
        print "", ( defined $token->get_pod_pattern ?  @{ $token->get_pod_pattern } : ""), " ";
        print "", ( defined $pat && defined $pat->[0] ? $pat->[0]->[0] : " key pat undef" ), "\n";
        $last  = $token;
        $token = $token->next;
    }

}

=head1 B<output_hash()>

    $parser->ouptut_hash

Calling this method before calling C<$p->parse_file($filename)> will have parse_file return a the parsing in hash.
The keys are the text after the pod directives (followed by a counter if the same text is met more than once.

=cut

sub output_hash {
    my $self = shift;
    my $out;
    open( $out, ">", \$h_value )
        or $self->{log}->logdie("Can't set a scalar ref as a file handle $!");
    $self->SUPER::output_fh($out);
    $self->{output_as_hash} = 1;
}

=head1 B<output_file( $filename )>

    $parser->output_file("selected_pod.txt");

Will write the file with the pod sections selected in the parsing.

=cut

sub output_file {
    my ( $self, $file ) = @_;
    my $fh;
    if ($file) {
        open $fh, ">", $file
            or $self->{log}->logdie("Can't open $file for writing $!");
    }
    else {
        $fh = *STDOUT{IO};
    }
    $self->SUPER::output_fh($fh);

}

=head1 B<parse_file( $file_to_parse )>

    $parser->parse_file("Select.pm");

This method run the parsing. It as to be called after C<$p->select(...)> and C>$p->output_file(...)> or C<$p->output_hash()>.

=cut

sub parse_file {
    my ( $self, $file ) = @_;
    tie my @array, 'Tie::File', $file, mode => O_RDONLY;
    $self->{log}->logconfess(
        "$file is seen as one line long by Tie::File\nPlease set the line ending according to your OS"
    ) if ( scalar(@array) == 1 );

    #$token_match = $self->{doc};
    $token       = $self->{doc}->next;
    # $self->{doc}->_print_patt;

    $self->SUPER::parse_file($file);

    if ($token->get_key eq "doc_Document_end_") { #ordered parsing, last token is the sentinel
        $token->previous->line_end( @array + 0) unless $token->previous->line_end;
    } 
    else { #unordered parsing: last token is the current token
        $token->line_end( @array + 0) unless $token->line_end; 
    }
    my $out = $self->{'output_fh'};
    my %data;
    $token = $self->{doc}->next;
    my $key_count;
    while ($token) {
        $token = $token->next if ( $token->children_count );
        my $key = $token->get_key;
         $key =~s/^.*_//; #keep only the last part of the key
        #array starts at 0 and line numbers starts at 1 ...
        my $first = $token->line_start() - 1;
        my $last  = $token->line_end() - 1;
        $self->{log}->debug( "key : ", $key, " ", $token->line_start(),
            " - ", $token->line_end() );
        for my $i ( $first .. $last ) {
            print $out $array[$i], "\n";
        }
        if ( $self->{output_as_hash} ) {
            while ( exists $data{$key} ) {
                $key_count++;
                $key .= " $key_count";
            }
            $data{$key} = $h_value;
            $h_value = undef;
            close $out;
            open $out, ">", \$h_value
                or $self->{log}->logdie("Can't open string for writing $!");
        }
        $token = $token->next;
    }
    close $out;
    untie @array;
    return %data if ( $self->{output_as_hash} );
}

#
#A handler to get the =cut positions in the file
#

sub cut_seen {
    my ( $line, $line_number, $self ) = @_;
    #my $mytoken = ( $token ? $token->previous : $token_match );
my $mytoken = $token->previous;
    $self->{log}->debug(
        $line_number, " token: ",
        $mytoken->get_key, " line_end: ", $mytoken->line_end,
        " replaced by ",
        $line_number - 1
    );
    $mytoken->line_end( $line_number - 1 ) unless ( $mytoken->line_end );
}

#
#The same handle for select args given in a hash ref (uo is for unordered)
#

sub cut_seen_uo {
    my ( $line, $line_number, $self ) = @_;
    $self->{log}->debug(
        $line_number,
        " token: ",
        (     $token
            ? $token->get_key . " line_end: " . $token->line_end
            : " undef"
        )
    );
    $token->line_end( $line_number - 1 ) unless ($token->line_end);

}

sub _handle_element_start {
    my ( $self, $e_name, $attr_hr ) = @_;

    #return unless $token;
    return
        unless defined $attr_hr->{"start_line"};

    #do nothing with C<>, L<> element

    $self->{log}->debug(
        "e_name: ",
        $e_name,
        " line: ",
        $attr_hr->{"start_line"},
        " token: ",
        (     $token
            ? $token->get_key
                . " key_needed: "
                . ( $token->key_needed() ? " true" : " false" )
            : " undef"
        )
    );

    if ( $token->is_pod_matching($e_name) ) {

        $self->{log}->debug(
            "current token: ", $token->get_key,
            " previous: ",     $token->previous->get_key
        );
        $token->line_start( $attr_hr->{"start_line"} );

      #Do not change a value set by _cut_seen, change only the 0 default value
        $token->previous->line_end( $attr_hr->{"start_line"} - 1 )
            if ( $token->previous->line_end() == 0 );
    }

    my $tp = $token->previous;

    if ( $token->key_needed() && $key ) {
        $self->{log}->debug( "testing : ", $token->get_key, " / ", $key );
        if ( $token->is_key_matching($key) ) {

            #$last_end = $attr_hr->{"start_line"} - 1;
            #Set the end of the previous token if it's not elready done
            $tp->line_end( $token->line_start - 1 ) unless ( $tp->line_end );
            #$token_match = $token;
            $self->{log}->debug("moving to the next token");
            $token = $token->next;

        }
        else {
            $self->{log}->debug( $token->get_key, " no match with $key" );

            #stop fetching text for the key since a match has be done
            $token->key_needed(0);
        }
        $key = undef;
    }    #if

    else {
        #key not needed or $key undef
        if ( $e_name =~ /^head/i ) {
            $self->{log}
                ->debug( "token->key_needed is false or key undef. tp current line end : ", $tp->line_end );
            #close the last token fetched if it's still 0
            $tp->line_end( $attr_hr->{"start_line"} - 1 )
                unless ( $tp->line_end );

        }
    }

}

#uo parsing: the compiled regex for the pod directives and the keys
#are in the root token for the whole parsing.
#The children token are created during the parsing when a key (from the file) matched with a key pattern
#The starting line and ending line are

sub _handle_element_start_uo {
    my ( $self, $e_name, $attr_hr ) = @_;
    return
        unless defined $attr_hr->{"start_line"};
    $token = $self->{doc} unless ($token);

    $self->{log}->debug(
        "e_name: ",
        $e_name,
        " line: ",
        $attr_hr->{"start_line"},
        " token: ",
        ( defined $token ) ? $token->get_key : " token undef",
        " key_needed: ",
        ( $self->{doc}->key_needed() ? " true" : " false" )
    );

    if ( $self->{doc}->is_pod_matching($e_name) ) {

        #put the line of the matching pod directive in the root token
        #the matching pod directive can be retrieve with $self->{doc}->get_pod
        $self->{doc}->line_start( $attr_hr->{"start_line"} );
        if ( $token->previous ) {
            $token->previous->line_end( $attr_hr->{"start_line"} - 1 )
                if ( $token->previous->line_end() == 0 );
        }
        else {
            $self->{log}->debug("tp undef");
        }

    }

    $self->{log}->debug(
        " self->{doc}->key_needed: ",
        ( $self->{doc}->key_needed() ? " true" : " false" ),
        " key is ", ( defined $key ? $key : " undef" )
    );

    if ( $self->{doc}->key_needed() && $key ) {

        $self->{log}->debug( "testing : ", $key );

        if ( $self->{doc}->is_key_matching($key) ) {
            $self->{log}->debug("Found match");

            #$last_end = $attr_hr->{"start_line"} - 1;
            if ( $token->previous ) {
                $token->previous->line_end( $attr_hr->{"start_line"} - 1 )
                    unless ( $token->previous->line_end );
            }
            else {
                $self->{log}->debug("tp undef");
            }
            $self->{log}->debug("next token - new token");

            my $new_token =
                Pod::Simple::Select::Token->new( $self->{doc},
                $self->{doc}->get_pod );

            $new_token->set_key($key);

            #retrieve back the line_start stored when the pod
            #dir of the current key was matching
            $new_token->line_start( $self->{doc}->line_start );

            #set the line end the soon to become previous token
            #unless the line_end already exists
            $token->line_end( $self->{doc}->line_start - 1 )
                unless ( $token->line_end );
            $new_token->previous($token);
            $token = $token->next($new_token);
        }    #if
        else {
            $self->{log}->debug(
                "no match ! pod_index: ",
                $self->{doc}->{pod_index},
                " keys ",
                join(
                    " ",
                    @{  $self->{doc}->{key_pat}->[ $self->{doc}->{pod_index} ]
                    }
                )
            );

            #set the line end of the current token before the start of
            #this section having a non matching key
            #tester =head1 found =head3 Non matching pod
            $token->line_end( $self->{doc}->line_start - 1 )
                unless ( $token->line_end );
        }
        $key = undef;
    }
    else {
        #key not needed or $key undef
        if ( $e_name =~ /^head/i ) {
            my $last_end = $attr_hr->{"start_line"} - 1;
            if ( $token->previous ) {
                $self->{log}->debug( "tp current line end : ",
                    $token->previous->line_end );

                $token->previous->line_end($last_end)
                    unless ( $token->previous->line_end );
            }
            else {
                $self->{log}->debug("tp undef");
            }

        }
    }

}


sub _handle_text {
    my ( $self, $text ) = @_;
    return unless $token;
    if ( $token->key_needed() ) {
        $key .= $text;
    }
    $self->{log}->debug($text);
}

sub _handle_text_uo {
    my ( $self, $text ) = @_;
    if ( $self->{doc}->key_needed() ) {
        $key .= $text;
    }
    $self->{log}->debug($text);

}


#
#Pod::Simple::Select::Token is used in both ordred unordered parsing
#It's not used outsite this module so it is not included in separate file
#
#Ordered parsing : a list of token ordred by next-previous links and parent-child links
#parent - child links are made by the args given in select
#next-previous is a deep first search in the tree made in $parser->make_tree
#{key_pat} holds an array ref of one array ref that hold the compiled regex of a key
#{pod_pat} holds an array ref of one array ref that hold .... of the pod directive
#{pod_index}  is 0 in every token
#{pod} is the pod directive received in the token contructor
#
#Unordered parsing: a list of token is made in _handle_element_start_uo when a pod directive 
#and key match with the keys and pod patterns stored in the root token (stored in $parser->{doc}
#all the token are children of the root, next-previous is a link between all these children token
#In the root token
#{pod_pat} holds an array ref of arrays ref, each having a compiled pod directives
#{key_pat} holds an array ref of arrays ref, each having a compiled regex for a key
#when a pod directive from the file matched, the index in the @{$self->{pod_array}}
#is stored in {pod_index}. So the corresponding array of compiled keys regex can be used
#in @{$self->{key_pat}} to test a match with a key.
#The pod directive that matched is remembered in $parser->{doc}->{pod}
#
package Pod::Simple::Select::Token;

#use Carp qw/confess/;
use Data::Dumper;
my $current_child = 0;

sub new {
    my ( $class, $parent, $pod_dir ) = @_;
    my $self->{parent} = $parent;
    bless $self, $class;

    if ($parent) {

        #index position of this token in the parent token
        $self->{index}      = $parent->add_child($self);
        $self->{level}      = $parent->{level} + 1;
        $self->{key}        = $parent->get_key . "_" . $pod_dir . "_";
        $self->{key_needed} = 0;
    }
    else {
        $self->{level}   = 0;
        $self->{key_pat} = [];
        $self->{key}     = $pod_dir;
    }
    $self->{pod_index} = 0;
    $self->{line_pos} = [ 0, 0 ];
    $self->set_pod_pattern($pod_dir);
    $self->{children} = [];
    $self->{log}      = Log::Log4perl::get_logger(__PACKAGE__);
    return $self;
}

sub set_key {
    my ( $self, $key ) = @_;
    $self->{log}->debug( " key: ", $key );
    $self->{key} .= $key;
    push @{ $self->{key_pat} }, [qr/\b$key\b/i];
}

sub get_key {
    return shift->{key};
}

sub get_key_pattern {
    my $self = shift;

    return $self->{key_pat};

}

sub get_pod_pattern {
    return shift->{pod_pat};
}

sub set_pod_pattern {
    my ( $self, $pod_dir ) = @_;
    if ( ref $pod_dir eq "ARRAY" ) {
        my @pat;
        for my $pod (@$pod_dir) {
            push @pat, qr/\b$pod\b/i;
        }
        $self->{pod_pat} = \@pat;
    }
    else {
        $self->{pod_pat} = [qr/\b$pod_dir\b/i];
        $self->{pod}     = $pod_dir
            ;    #ordered args: holds the head1 etc given in the select call
                 #unordered args : holds the pod_directive last match
    }
}

sub add_child {
    my ( $self, $child ) = @_;
    $self->{first_child} = $child
        unless ( scalar @{ $self->{children} } );
    push @{ $self->{children} }, $child;
    return @{ $self->{children} } - 1;

    #next est le premier ne s'il y a des descendants
    #sinon c est le voisin de meme niveau
}

sub previous {
    my ( $self, $v ) = @_;
    if ($v) {
        $self->{previous} = $v;
    }
    return $self->{previous} if ( $self->{previous} );
}

sub next {
    my ( $self, $v ) = @_;
    if ($v) {
        $self->{next} = $v;
    }

=for comment
     if ($self->{first_child} && ! $seen{ $self->{key} }) {
        $seen{ $self->{key}}= 1;
        return $self->{first_child};
    }
    return $self->{parent}->child_at($self->{index}+1) if ( $self->{parent});
    # return $self->{parent}->next if ($self->{parent});
=cut

    return $self->{next} if ( $self->{next} );
}
#
#Return the token at pos $index if $index is in the range of 0 -> last_child (: children_count -1)
#Else if there is a parent, return the next sibling 
#(the token next to the current token in the parent children list
#
sub child_at {
    my ( $self, $index ) = @_;
    $self->{log}->logconfess("called on an empty list")
        unless $self->children_count;
    $self->{log}
        ->debug( "searching ", $index, " in 0-", @{ $self->{children} } - 1,
        " indexes" );
    if ( $index < @{ $self->{children} } ) {
        return $self->{children}->[$index];
    }
    else {
        return $self->{parent}->child_at( $self->{index} + 1 )
            if ( $self->{parent} );
    }

}

sub children {
    return @{ shift->{children} };
}

sub line_start {
    my ( $self, $pos ) = @_;
    if ($pos) {
        $self->{line_pos}->[0] = $pos;
        $self->{log}
            ->debug( "line_start: ", $self->get_key, " set at ", $pos );
    }
    return $self->{line_pos}->[0];
}

sub line_end {
    my ( $self, $pos ) = @_;
    if ($pos) {
        $self->{line_pos}->[1] = $pos;
        $self->{log}->debug( $self->get_key, " set at ", $pos );

    }
    return $self->{line_pos}->[1];
}

sub next_index {
    return shift->{index} + 1;
}

sub children_count {
    my $self = shift;
    my $res  = @{ $self->{children} };
    return $res;

}

sub get_level {
    return shift->{level};
}

sub is_pod_matching {
    my ( $self, $el ) = @_;
    $self->{log}->logconfess("can't treat undef") unless ($el);

    if ( $self->{pod_pat} ) {
        my $i = 0;
        for my $p ( @{ $self->{pod_pat} } ) {
            $i++;
            if ( $el =~ /\b$p\b/ ) {
                $self->{key_needed} = 1;
                $self->{pod_index}  = $i - 1;
                $self->{pod}        = $el;
                $self->{log}->debug( "Found pod match for ",
                    $self->get_key, " and ", $el, " with index ",
                    $self->{pod_index} );
                return 1;
            }
        }
    }
    return 0;
}

sub is_key_matching {
    my ( $self, $el ) = @_;
    $self->{log}->logconfess("can't treat undef") unless ($el);
    my $key_r = $self->{key_pat}->[ $self->{pod_index} ];
    $self->{log}->debug("is_key_matching index:", $self->{pod_index});
    $self->{key_needed} = 0;
    $self->{log}->debug("key_needed set to 0");
    for my $p (@$key_r) {
        $self->{log}->debug("searching $el pattern: $p");
        if ( $el =~ /\b$p\b/ ) {
            $self->set_key($el) unless $self->{key};
            $self->{log}->debug( "Found key match for ",
                $self->get_key, " and ", $el );
            #$self->{key_needed} = 0;
            return 1;
        }
    }
    return 0;

}

sub get_pod {
    return shift->{pod};
}

sub key_needed {
    my ( $self, $v ) = @_;
    $self->{key_needed} = $v if ( defined $v );
    return $self->{key_needed};
}

sub _print_patt {
    my $self = shift;
    print "print_patt ", Dumper( $self->{pod_pat} ), "\n";
    if ( ref $self->{key_pat} ) {
        for my $k ( @{ $self->{key_pat} } ) {
            print "key_pat ", Dumper(@$k), "\n";
        }
    }
    else {
        print "key_pat ", $self->{key_pat}, "\n";
    }
}

1;

=head1 BUGS

See support below.

=head1 SUPPORT

Any questions or problems can be posted to me (rappazf) on my gmail account. 

=head1 AUTHOR

    FranE<ccedil>ois Rappaz
    CPAN ID: RAPPAZF

=head1 COPYRIGHT

FranE<ccedil>ois Rappaz 2017
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Pod::Simple>

L<Tie::File>

=cut

