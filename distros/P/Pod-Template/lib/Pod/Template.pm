package Pod::Template;

use File::Spec;
use FileHandle;
use Params::Check                   qw[check];
use Locale::Maketext::Simple Style  => 'gettext';

use strict;
use vars qw[@ISA $VERSION $DEBUG $WARNINGS];

$VERSION    = 0.02;
$DEBUG      = 0;
$WARNINGS   = 1;

$Params::Check::VERBOSE = 1;

=pod

=head1 NAME

Pod::Template - Building pod documentation from templates.

=head1 SYNOPSIS

    ### As a module ###
    use Pod::Template;
    my $parser = new Pod::Template;
    $parser->parse( template => 'documentation.ptmpl' );

    print $parser->as_string


    ### As a script ###
    $ podtmpl -I dir1 -I dir2 documentation.ptmpl


    ### A simple module prepared to use Pod::Template ###
    package My::Module;
    
    =Template print_me
    =head2 print_me( $string )
    
    Prints out its argument.
    
    =cut
    
    sub print_me { print shift; return 1 }

    
    ### A simple pod file named Extra/Additional.pod ###
    =pod
    =Template return_vals
    
    This subroutine returns 1 for success and undef for failure.

    =cut

    
    ### A simple Pod::Template template ###
    =Include My::Module
    =Include Extra/Additional.pod as Extra
    
    =pod
    
    =head1 SYNOPSIS
    
        use My::Module
        
        My::Module::print_me('some text');
    
    =head2 Functions
    
    =Insert My::Module->print_me

    =Insert Extra->return_vals
    
    =cut


=head1 DESCRIPTION 

Writing documentation on a project maintained by several people
which spans more than one module is a tricky matter.  There are
many things to consider:

=over 4

=item Location

Should pod be inline (above every function), at the bottom of the
module, or in a distinct file?  The first is easier for the developers,
but the latter two are better for the pod maintainers.

=item Order

What order should the documentation be in?  Does it belong in the
order in which the functions are written, or ordered by another
principle, such as frequency of use or function type?  Again, the
first option is better for the developers, while the second two
are better for the user.

=item References

How should a function in another file be mentioned?  Should the
documentation simply say 'see L<Other::Module>', or should it include
the relevant section?  Duplication means that the documentation
is more likely to be outdated, but it's bad for a user to have to
read numerous documents to simply find out what an inherited
method does.

=item Headers & Footers

What should be done with standard headers and footers?  Should they
be pasted in to every file, or can the main file be assumed to cover
the entire project?  

=back

Pod::Template offers a solution to these problems: documentation is
built up from templates. 

Assume that you have a module and a template as outlined in the
SYNOPOSIS.  Running this template through Pod::Template will result
in this documentation:

    =pod
    
    =head1 SYNOPSIS
    
        use My::Module
        
        My::Module::print_me('some text');
    
    =head2 Functions
    
    =head2 print_me( $string )
    
    Prints out its argument.

    This subroutine returns 1 for success and undef for failure.
    
    =cut

=head1 TEMPLATE RULES

=over 4

Use =Include to specify which sources will be used:

    =Include Some::Module

With the =Include directive, it is possible to specify an alternate
name to use with =Insert statements:

    =Include FileName as KnownName

If a file extension is not specified, =Include will look first for a
.pm file, and then for a file without an extension.  You may also
specify the path (in which case the complete file name must be provided)
to handle situations where there could be namespace collisions:

    =Include Some::Module::File as SMFile
    =Include Another/Module/File.pod as AMFile

The =Insert function
works by including text from the named =Template directive
until the first =cut or the next =Template directive.  First specify
the source, followed by C<-E<gt>>, then the =Template directive name:

    =Insert IncludedFile->marked_text

See the C<samples> directory in the distribution for further examples on
how to use Pod::Template.

=head1 METHODS

=head2 new( [lib => \@libs] ) 
    
Create a new instance of Pod::Template.

Optionally, you can provide the C<lib> argument to change the library
path that Pod::Template looks for files. This defaults to your C<@INC>.    

=cut    
{
    my $tmpl    = {
        lib         => { default => \@INC },
        include     => { default => {}, no_override => 1 },
        store       => { default => {}, no_override => 1 },
        parsed      => { default => '', no_override => 1 },        
    };        
    
    sub new {
        my $class   = shift;
        my %hash    = @_;
         
    
        my $args = check( $tmpl, \%hash ) or return;
        return bless $args, $class;
    }
    
    ### autogenerate accessors ###
    for my $key ( keys %$tmpl ) {
        no strict 'refs';
        *{__PACKAGE__."::$key"} = sub {
            my $self = shift;
            $self->{$key} = $_[0] if @_;
            return $self->{$key};
        }
    }
}

=head2 parse( template => $template_file );

Takes a template file and parses it, replacing all C<Insert> 
directives with the requested pod where possible, and removing
all C<Include> directives.

Returns true on success and false on failure.

=cut

sub parse {
    my $self = shift;
    my %hash = @_;

    my ($file);
    my $tmpl = {
        template    => { required => 1, store => \$file,
                            allow => sub { -e pop() } },
        #as          => { required => 1, store => \$as },                 
    };
    
    check( $tmpl, \%hash ) or return;

    $self->_parse_file( file => $file, add_pod => 1 ) or return;
    
    return 1;
}

=head2 as_string

Returns the result of the parsed template as a string, ready to be
printed.

=cut

sub as_string { my $self = shift; return $self->parsed };


sub _parse_file {
    my $self = shift;
    my %hash = @_;
    
    my ($file,$add_pod, $as);
    my $tmpl = {
        file    => { required => 1, store => \$file },
        as      => { default => '', store => \$as },
        add_pod => { default => 0, store => \$add_pod },
    };     

    check( $tmpl, \%hash ) or return;
    $as ||= $file;
  
    my $fh = $self->_open_file( $file ) or return;
    
    print loc(qq[%1: Parsing file '%2'\n], $self->_me, $file) if $DEBUG;
    
    my $active = '';
    while(<$fh>) {
    
        if( s/^=Template\s*(.+?)\s*$// ) {
            $active = $1;     
        
            print loc(  qq[%1: Found '%2' directive on line %3: '%4'\n], 
                        $self->_me, 'Template', $., $active) if $DEBUG;
    
        } elsif( $active && /^=cut\s*/ ) {
            $active = '';
        
            print loc(  qq[%1: Found '%2' directive on line %3\n], 
                        $self->_me, 'cut', $.) if $DEBUG;
        }
        
        ### it's a Template directive ###
        if( $active ) {
            $self->store->{$as}->{$active} .= $_;   
        
        ### parse the include part ###
        } elsif ( s/^=Include\s*(.+?)\s*$// ) {
            my $part = $1;
        
            print loc(  qq[%1: Found '%2' directive on line %3: '%4'\n], 
                        $self->_me, 'Include', $., $part) if $DEBUG;
            
            if( $part =~ /(.+?)\s+as\s+([\w:]+)\s*$/i ) { 
                $self->_parse_include(
                        include => $1,
                        as      => $2, 
                );
            } else {
                $self->_parse_include( include => $part );
            }     
        
        ### insert directive ###              
        } elsif ( s/^=Insert\s*(.+?)->(.+?)\s*$// ) {
            my $mod     = $1;
            my $func    = $2;
            
            my $str;
            $str =  $self->store->{$mod}->{$func} 
                    if exists $self->store->{$mod}->{$func};
    
            $str
                ? $self->parsed( $self->parsed . $str )
                : warn loc( qq[Could not retrieve insert '%1' from '%2'. ] .
                            qq[Perhaps you forgot to include '%3'?\n], 
                            $func, $mod, $mod );
    
        } else {
        
            $self->parsed( $self->parsed . $_ ) if $add_pod;
        }      
    }
    
    return 1;
}      

sub _parse_include {    
    my $self    = shift;
    my %hash    = @_;
    
    my ($include,$as);
    my $tmpl    = {
        include => { required => 1, store => \$include },
        as      => { default => '', store => \$as },
    };     
    
    check( $tmpl, \%hash ) or return;
    
    ### it has to have a name ###
    $as ||= $include;
    
    print loc(  qq[%1: Parsing include '%2' as '%3'\n], 
                $self->_me, $include, $as) if $DEBUG;
    
    my $file = $self->_find_file_from_include( $include ) or return;
    
    if( exists $self->include->{$include} ) {
        
        ### trying to do the same one again? ###
        if( $self->include->{$include}->{as}    eq $as  and     
            $self->include->{$include}->{file}  eq $file
        ) {
            return 1; 
         
        } elsif (   $self->include->{$include}->{as}    ne $as      or
                    $self->include->{$include}->{file}  ne $file
        ) {              
            warn loc(q[Conflicting include; Attempting to include '%1' as '%2' ] .
                     q[but it's already it's already included from file '%3' as '%4],
                     $file, $as, $self->include->{$include}->{file},
                     $self->include->{$include}->{as} ) if $WARNINGS;               
        }
    } else {
        
        ### store it ###
        $self->include->{$include} = { file => $file, as => $as };
    
        $self->_parse_file( file => $file, as => $as );
    }
    
    return 1;
}

sub _find_file_from_include {
    my $self    = shift;
    my $include = shift or return;
    
    ### figure out what files to look for -- 
    ### is it a module, or a file? use the same rules as Module::Load
    my @try;
    if( $self->_is_file( $include ) ) {
        push @try, $include;    
    } else {
        for my $flag (qw[1 0]) {
            push @try, $self->_to_file( $include, $flag );
        }           
    }
    
    for my $dir ( @{$self->lib} ) {

        ### someone put a ref in @INC, or the include path ###
        next if ref $dir;

        ### dir doesn't exist ###
        next unless -d $dir;

        for my $try (@try) {       
            my $file = File::Spec->catfile( $dir, $try );      

            print loc(qq[%1: Trying file '%2'\n], $self->_me, $file) if $DEBUG;

            return $file if -e $file;
        }
    }

    warn loc(qq[Could not find suitable file from include: '%1'\n], $include); 
    return;
}

sub _open_file {
    my $self = shift;
    my $file = shift or return;
    
    print loc(qq[%1: Opening '%2'\n], $self->_me, $file) if $DEBUG;
    
    my $fh = FileHandle->new($file) 
                or( warn(loc(qq[Could not open file '%1': %2\n],$file, $!)),
                    return
                );     

    return $fh;
}


### stolen from Module::Load ###
sub _to_file{
    my $self    = shift;
    local $_    = shift;
    my $pm      = shift || '';

    my @parts = split /::/;

    ### because of [perl #19213], see caveats ###
    my $file = $^O eq 'MSWin32'
                    ? join "/", @parts
                    : File::Spec->catfile( @parts );

    $file   .= '.pm' if $pm;

    return $file;
}

sub _is_file {
    my $self = shift;
    local $_ = shift;
    return  /^\./               ? 1 :
            /[^\w:']/           ? 1 :
            undef
    #' silly bbedit..
}
### end theft ###

sub _me { return (caller 1)[3] }

1;

__END__

=pod

=head1 GLOBAL VARIABLES

=head2 $Pod::Template::WARNINGS

If this variable is set to true, warnings will be issued when 
conflicting directives or possible mistakes are encountered.
By default this variable is true.

=head2 $Pod::Template::DEBUG

Set this variable to true to issue debug information when 
Pod::Template is parsing your template file.

This is particularly useful if Pod::Template is generating output
you are not expecting.  The default value is false.

=head1 EXAMPLES

See the C<samples> directory in the distribution for examples on
how to use Pod::Template.

=head1 SEE ALSO

If this templating system is not extensive enough to suit your needs,
you might consider using Mark Overmeer's C<OODoc>.

=head1 AUTHOR

This module by Jos Boumans C<kane@cpan.org>.

=head1 COPYRIGHT

This module is
copyright (c) 2003 Jos Boumans E<lt>kane@cpan.orgE<gt>.
All rights reserved.

This library is free software;
you may redistribute and/or modify it under the same
terms as Perl itself.
