package TemplateRex;

$TemplateRex::VERSION = '2.0';

#use strict;
use warnings;

use Data::Dumper 

require Exporter;

our @ISA = qw(Exporter);

# --------------------------
# Class Data and methods
{
  my %default_hsh;

  $default_hsh{'sub_dir'}           = "templates";
  $default_hsh{'inc_dir_lst'}       = ['.'];

  $default_hsh{'cmnt_verbose'}      = 1;
  $default_hsh{'cmnt_prefix_char'}  = '<!--';
  $default_hsh{'cmnt_postfix_char'} = '-->';

  $default_hsh{'func_prefix'}  = '_';
  $default_hsh{'func_package'} = "";
  $default_hsh{'func_flg'}     = 0;
 
  # Class methods
  sub set_defaults
  {
    my $class = shift @_;

    my %set_hsh;
    if (  ref($_[0]) eq "HASH" ) { %set_hsh = %{ $_[0] } }
    else                         { %set_hsh = @_         }

    # Merge with existing hash
    %default_hsh = ( %default_hsh, %set_hsh);

    return %default_hsh;
  }

  sub get_defaults
  {
    return %default_hsh;
  }
}

#-----------------------------------------------------
#  Object modify the inc lst
#-----------------------------------------------------
sub inc_lst
{
   TemplateRex::set_defaults( {'inc_dir_lst'=>$_} );
}


# --------------------------
# Heavy lifting constructor
sub new
{
  my $caller = shift @_;

  # In case someone wants to sub-class
  my $caller_is_obj  = ref($caller);
  my $class = $caller_is_obj || $caller;

  # Passing reference or hash
  my %arg_hsh;
  if ( ref($_[0]) eq "HASH" ) { %arg_hsh = %{ shift @_ } }
  else                        { %arg_hsh = @_ }

  # verify input
  unless ( ( $arg_hsh{'str'} ) || ( $arg_hsh{'file'} ) ) { _debug("Must specify a file OR str") }

  # Override default hash with arguments
  #my %conf_hsh = TemplateRex->get_defaults();
  my %conf_hsh = __PACKAGE__->get_defaults();

  %conf_hsh = (%conf_hsh, %arg_hsh);
  
  # Set package for embedded function to caller unless otherwise specified.
  unless ( $conf_hsh{'func_package'} ) { $conf_hsh{'func_package'} = (caller)[0] }

  # The object data structure
  my $self = bless {
                        'temp'      => {},
                        'temp_tree' => {},
                        'func_tree' => {},
                        'data'      => {},
                        'conf'      => { %conf_hsh },
                      }, $class;

  # Read in a template based on a search list
  my $str = $arg_hsh{'str'} || $self->read_template( $arg_hsh{'file'} );

  # Preload to get the ball rolling . . .
  $self->{'temp'}->{'main'} = $str;
  my @temp_lst = ('main'); 

  foreach my $key ( @temp_lst )
  {
    $str = $self->{'temp'}->{"$key"};
    my ($temp_hsh_ref, $func_hsh_ref) = $self->process_template( \$str, $key );

    my @i_temp_lst = keys %{$temp_hsh_ref};

    @{ $self->{temp} }{@i_temp_lst} = @{ $temp_hsh_ref }{@i_temp_lst}; # slices of hashes

    @i_temp_lst = grep { $_ ne $key } @i_temp_lst;

    $self->{'func_tree'}->{"$key"} = { %{$func_hsh_ref} };
    $self->{'temp_tree'}->{"$key"} = [ @i_temp_lst ];

    push @temp_lst, @i_temp_lst;   # Twiddle with the looping list
  }

  # Whew that was hard work . . .
  return $self;
}

#--------------------------------------------
# $str = $self->read_template($template_name)
#--------------------------------------------
# Finds a template based on a
# search list and returns a string.
#---------------------------------------------
sub read_template
{
   my $self = shift @_;
   my $template_file = shift @_;

   # Dereference
   my @inc_dir_lst = @{ $self->{'conf'}->{'inc_dir_lst'} };
   my $sub_dir     = $self->{'conf'}->{'sub_dir'};

   # Tack on some a default
   unless ( @inc_dir_lst) { @inc_dir_lst = ( "." ) };

   my @sub_dirs;
   if($sub_dir){
      foreach (@inc_dir_lst){
          push(@sub_dirs,"$_/$sub_dir");
      }
   }

   my ($str, $fspec);
   foreach ( @inc_dir_lst, @sub_dirs )
   {

     $fspec = "$_/$template_file";

     ##_debug("\n $fspec");

     if (-e $fspec )
     {
         open(FID,$fspec) or die "can't open $fspec: $!\n";
         $str =  join "", <FID>;
         last;
     }
   }

   unless ($str) { _debug("Cannot find $template_file file") };

   # Execute special file includes
   $str =~ s/\&include_file\(['"]*(.*?)['"]*\)/ $self->read_template($1,\@inc_dir_lst,$sub_dir) /eg;

   # Bracket the template with comment 
   my $rtn_str;
   if ( $self->{'conf'}->{'cmnt_verbose'} ) {

     my $doctype;    
	 if ( $str =~ m/^<!/ ) { if ( $str =~ s/^(<![^>]*>)// ) { $doctype = "$1\n" } } # If leading doctype it has to be first. 
      
     $rtn_str  = "${doctype}$self->{'conf'}->{'cmnt_prefix_char'} template file $fspec below $self->{'conf'}->{'cmnt_postfix_char'}\n";
     $rtn_str .= $str;
     $rtn_str .= "\n$self->{'conf'}->{'cmnt_prefix_char'} template file $fspec above $self->{'conf'}->{'cmnt_postfix_char'}\n";
   } else { $rtn_str = $str }

   return $rtn_str;
}

#-----------------------------------------------------
# ($template_hsh_ref, $fn_hsh_ref) = process_template($str)
#-----------------------------------------------------
#
# Parses out inner templates sandwiched by protocol defined
# as follows.
#
# <!-- begin name=my_inner -->
#      Inner template stuff such as
#      <tr><td> $row </td></tr>
# <!-- end   name=my_inner -->
#
# Returns hash ref that is of the format
# $template_hsh{'main'}     = input string with inner templates parsed out
# $template_hsh{'my_inner'} = inner template string
#
# note: 'main' is a reserved keyword for this function.
#
# Also Parses out functions as follows.
#
# @func_name('arg1',$dynamic_arg) and replaces with
#
#   $func_name__arg1_dynamic_arg
#
# Returns a hash ref such as
#
# $fn_hsh{'func_name_arg1_dynamic_arg'} = 'func_name('arg1',$dyanamic_arg)'
#
# The hash elements are suitable for eval'ing
#
# Warning! this makes these different functions equivalent
# @get_tag('name',$cust) and @get_tag($name,cust)
#-----------------------------------------------------
sub process_template
{
   my ($self) = shift @_;
   my ($str)  = shift @_;


   # Allow passing of a reference if desired.
   if (  ref($str) =~ "SCALAR" ) { $str = ${$str} };

   my $tag = shift @_;
   unless ( $tag ) {  $tag = 'main' }

   my %temp_hsh;

   # First Process Inner Templates
   my ($str_new, $tail);

   # Replace \n's with special char and then do the inverse after processing
   # The regexp processing was found to be _very_ slow if lots of \n's exist in template.
   my $spec_chr = chr(7);     # Bell char (as good as any?)
   #   $str =~ s/\n/$spec_chr/g;

   # Huge penalty for "i" on this match on perl 5.10.1 
   while (  $str =~ /(.*?)<!--\s+BEGIN\s+name=(\w+)\s*-->(.*)<!--\s+END\s+name=\2 .*?-->/gsp )
   {
     $str_new .= "$1\$$2";
     $temp_hsh{$2} = $3;
     $tail = ${^POSTMATCH};
   }

   # If no patterns were found then str_new would be blank
   if ($str_new) {  $str = $str_new . $tail }

   # Second Process Functions
   my $str_new;  my $tail;
   my %func_hsh;

   if ( $self->{conf}->{func_flg} ) 
   {
      # Note the "i" flag speeds up this match ~3000%   
      while (  $str =~ /(.*?)\&(\w+)\((.*?)\)/gisp )
      {
         my $prefix = $1;
		 my $func   = $2;
		 my $args   = $3;
		 $tail = ${^POSTMATCH};

		 # Build a function id base on function name and args
		 my $fn_id = "${func}__${args}";
		 $fn_id =~ s/\s*\,\s*/_/g;
		 $fn_id =~ s/\W//g;

		 $func_hsh{"$fn_id"} = "$func($args)";

		 $str_new .= "$prefix\$$fn_id";
	  }
      if ($str_new) { $str = $str_new . $tail}
   } 

   # Change back to \n's
#   $str =~ s/$spec_chr/\n/g;

   $temp_hsh{"$tag"} = $str;

   return(\%temp_hsh, \%func_hsh);
}

#-----------------------------------------------------
#  Render a sub-component
#-----------------------------------------------------
sub render_sec
{
   my ( $self, $sec_name, $hsh_ref, $opt_ref ) = @_;

   if ( ($hsh_ref) && (ref($hsh_ref) ne "HASH") ) { _debug("Opps Expecting Hsh Ref for \"$sec_name\"") } ;
   my %hsh = %{ $hsh_ref };

   %hsh = ( %hsh, %{ $self->{'data'} }  );

   # Dereference a few things for convience
   my $package = $self->{'conf'}->{'func_package'};
   my $prefix  = $self->{'conf'}->{'func_prefix'};
   my %func_hsh = %{ $self->{'func_tree'}->{$sec_name} };

   foreach ( keys %func_hsh )
   {
       my $func    = "${package}::${prefix}$func_hsh{$_}";
       $hsh{$_} = eval( $func );
   }

   my $str = $self->{'temp'}->{"$sec_name"};

   my $spec_chr = chr(7);
   if ( $opt_ref->{'esc'} ) { $str =~ s/\\\$/$spec_chr/g }

   # The find and replace
   #my $value; 

   $str =~ s/\$\{*(\w+)\}*/ my $value = $1;
                            $hsh{$value};
                          /ge;

   if ( $opt_ref->{'esc'} ) { $str =~ s/$spec_chr/\$/g }

   $self->{'data'}->{"$sec_name"} .= $str;

   # Garbage collection: remove lower hierarchy elements
   my @lst = @{ $self->{'temp_tree'}->{"$sec_name"} };
   foreach my $sub_sec_name ( @lst )
   {
      delete $self->{'data'}->{"$sub_sec_name"};
   }

   #if (defined wantarray) { return $str }
   return $str;
}

#-----------------------------------------------------
#  Render main
#-----------------------------------------------------
sub render
{
   my ( $self, $hsh_ref, $fn_or_fh, $opt_ref ) = @_;

   my $str = $self->render_sec('main', $hsh_ref, $opt_ref );
 
   if ($fn_or_fh)
   {
     if ( fileno $fn_or_fh ) { print $fn_or_fh $str }
     else
     {
        open (FID, ">$fn_or_fh") || _debug ("Can't open $fn_or_fh");
        print FID $str;
        close (FID);
     }
   }

   delete $self->{'data'};

   return $str;
}

#----------------------------
#  Retrieve sections
#----------------------------
sub get_sections
{
   my ( $self, $sec ) = @_;

   unless ( $sec ) { $sec = "main" }

   return $self->{'temp_tree'}->{$sec};
}

#-----------------------------------------------------
#  Render_this non OO function does the whole shebang
#-----------------------------------------------------
sub render_this
{
   my ( $hsh_ref, $data_ref ) = @_;
   my $self = new (__PACKAGE__, $hsh_ref);
   return $self->render($data_ref);
}

#-----------------------------------------------------
#  Clear Section
#-----------------------------------------------------
sub clear_sec
{
   my ( $self, $sec_name ) = @_;
   delete $self->{'data'}->{"$sec_name"};
}

#-----------------------------------------------------
#  Clear The Works
#-----------------------------------------------------
sub clear
{
   my ( $self, $sec_name ) = @_;
   $self->{'data'} = {};
}

#-----------------------------------------------------
#  Local debug display
#-----------------------------------------------------
sub _debug
{
   # Are in a web server kinda environment ?
   if ($ENV{'SERVER_ADDR'}) { print "Content-type: text/html\n\n<pre>" }
   print Dumper @_;
}

my $positive_note = 1;


__DATA__


=head1 NAME

TemplateRex - A Template toolkit that partitions code from text and uses nestable sections.

=head1 SYNOPIS

 # Assuming you have the following:
 # 1. Template file - "my_template.html"
 # 2. Hash consisting of the data to merge with the template - %data_hsh

 use TemplateRex;

 $args{'file'} = "my_template.html";

 $t_rex = new TemplateRex( %args );            # Arguments can be either a hash or hash reference

 $t_rex->render(\%data_hsh);                   # Prints to standard out
 $t_rex->render(\%data_hsh, "rendered.html")   # Prints to a file

 # Or a functional interface
 render_this(\%args, \%data_hsh);
 render_this(\%args, \%data_hsh, "rendered.html");


=head1 DESCRIPTION

The objective of TemplateRex is to achieve complete separation between
code and presentation. While this module was developed with html generation
in mind it works equally well with any text based files (such as gnuplot scripts).

Most CGI web based application start off with placing all the html text within print
statements in the code or generate html via functions such as with CGI.pm.  For applications
of any size or sophistication this approach quickly develops maintenance issues such as

=over 2

=item *
Code becomes bloated with embedded html.

=item *
Cannot leaverage the use of wysiwyg html generators (Dreamweaver, Frontpage).

=item *
The html is within the domain of the code programmer and not the html designers.

=back

Templates solve this problem by outsourcing the presentation or html outside the code.
The next step of evolution is then to place code within the html (asp, php, jsp) to handle
things like generating rows of a table or repeated sections or chunks of html.  The problem
with appoach are

=over 2

=item *
HTML becomes bloated with embedded code

=item * If you are using several 'skins' or templates sets for a different look-and-feel
for an application, pieces of code tend to be replicated in different templates sets.

=item * Cannot leaverage the use of wysiwyg html generators (Dreamweaver, Frontpage).

=item * Security issues with templates being able to execute code.  That is you need
to be able to 'trust' your template designers.

=back

It is the opinion of the author that both extremes present their own sets of problems and
that partitioning of code from presentation into their own separate realms is the best approach
for long term maintenance of large and/or sophisticated web applications.

=head2 Variable Replacement

At the most basic level this module replaces "$variables" within your template with
values of a data hash. For example, if you have a hash with a key of "time" and some
value then that value will replace each $time in your template.

$data{time} = "Fri Jul 19 17:30:20 PDT 2002";


Template file:

   It is now '$time'

Rendered html:

   It is now 'Fri Jul 19 17:30:20 PDT 2002'

=head2 Triggered Function Calls

In addition the template processor can run user definded Perl functions.
For example if a function exists in your code such as:

sub _get_time { return scaler localtime }

Template file

   It is now &get_time()

Rendered html

   It is now Fri Jul 19 17:30:20 PDT 2002

Note the use of the underscore prefix is to prevent a template author from
running any function within your code.  Therefore all functions that you
want to trigger from the html template should be defined with a prefix.
The underscore is the default prefix but this default can redefined.

You can even pass arguments to the triggered function.  For example if you have
a defined function such as:

sub _get_time
{
 $arg = shift @_;
 return scalar localtime($arg)
}

Template file:

   Last modified on &get_time(1042133373)

Rendered html:

   Last modified on Thu Jan  9 09:32:45 2003

There is one reserved function call &include_file('my_header.html') that will include
the specified file at the location of were the function is specified.


=head2 Template Section Parsing

However the unique and most useful part of TemplateRex is the ability to parse a template
based on sections. A template can be sectioned up using html comment delimiters such as

  <!-- BEGIN NAME=error_code  -->

    You Must Enter Your Credit Card Number !

  <!-- END NAME=error_code  -->


This defines a section with the name "error_code" which could be optionally rendered or
ignored.  For example if you had the above section in your template then the following:

 $t_rex = new TemplateRex( { 'file'=>"my_template.html" }  );

 unless ($cc_num) {  $t_rex->render_sec('error_code') }
 $t_rex->render();


Would insert the error string in the rendered template if $cc_num was not defined.
If $cc_num was defined then the error message would not appear in the rendered
template.

Sections can be reused and nested.  If a template section is called more than once then the
rendered section is automatically appended or accumulated.  If a section is nested than the
lower level accumulation is not rendered until the parent section is rendered.  This is best
demonstrated with a simple example.

If we have a template as shown below that consists of a "tbl" section with a nested "row" section.
This template will be used to render a two column table with a header showing the keys and values
of the global %ENV hash.

Template file:


     Current Environment Settings <br>
     <!-- BEGIN NAME=tbl  -->
        <table>
          <tr>
            <th> Key    </th>
            <th> Value  </th>
          </tr>

          <!-- BEGIN NAME=row -->
          <tr>
            <td> $key   </td>
            <td> "$value" </td>
          </tr>
          <!-- END NAME=row -->

        </table>
     <!-- END NAME=tbl  -->

Now assume you have some code such as:

 $t_rex = new TemplateRex( { 'file'=>"my_template.html" }  );

 foreach $key (keys %ENV)
 {
   $data_hsh{'key'}   = $key;
   $data_hsh{'value'} = $value;

   $t_rex->render_sec('row', \%data_hsh);   # Render and accumulate rows
 }

 $t_rex->render_sec('tbl');                 # Render the table with the accumulated rows

 $t_rex->render();                          # Render the complete template


The code and template would render something like:

Rendered html


   Key       Value
   HOME      "/home/httpd"
   HOST      "webdev"
   ...
   SHELL     "/bin/tcsh"
   TERM      "xterm"


The power in this is that the table can be generated and previewed in
any HTML editor before the data is rendered so that changes to the table can be made completely
independent of the Perl coding and data rendering process.

=head2 Template Where Art Thou

Templates are expected by default to be in either the current working directory '.' or './templates'.
If the requested template cannot be found in the current directory then it will look in a
templates sub-directory.  This search path can be modified or appended to by using the 'inc_dir_lst' parameter
and the set_defaults() class method.


=head2 Default Parameters


 * inc_dir_lst       - A reference to a list of directories where templates reside.  The list
 is searched recursively until the a template is found.  Default [ '.', './templates' ]

 * cmnt_verbose      - A flag signalling the template processor to embed the location or source
 of the underlying templates.  Default 1

 * cmnt_prefix_char  - The prefix comment character used if cmnt_verbose flag is set.
 Default '<!--'

 * cmnt_postfix_char - The postfix comment character used if cmnt_verbose flag is set
 Default  '-->'

 * func_prefix       - The prefix added to an embedded function in a temlate.  A prefix is
 used to prevent a template from running any user or native function (such as unlink('*')).
 Default '_'

 * func_package      - The default package where embedded function are called.  This allows
 an application to restrict all template triggered functions to a specific package. Default
 "" which translates to the main package.


The default parameters can be retrieved and set using the B<class> methods

 %config_hsh = TemplateRex->get_defaults();

 TemplateRex->set_defaults(%config_hsh);

The set_defaults class method sets the defaults for all subsequent TemplateRex instances for a session.
Also, the set_defaults methods merges with the existing defaults so that you can change one default without
overwriting the other defaults.

  $hsh{'func_prefix'} = "my_callbacks_";

  TemplateRex->set_defaults(%hsh);

Will only set the 'func_prefix' parameter leaving the others as they were.  The defaults can also be
set at object creation.  See METHOD below for more infomation.


=head1 METHODS

=head2 new

synopsis: B<$trex_obj = new( 'file'=E<gt>"my_template.html", %config )>

The input to the new() method requires a hash with at least a 'file' or 'string' parameter defined.  If
'file' is provided then the contructor will search the include path for the template and then read and preprocess the
template.  If 'string' is provided then the contructor will preprocess the string template.

=head2  render_sec

synopsis: B<$str = $trex_obj-E<gt>render_sec( 'section_name', \%data_hsh )>

The render_sec() will render the given 'section_name' using the provided %data_hsh for replacement values.
Note: The data hash must be passed down as a reference.  The render_sec() function will maintain a buffer
that is appended to on each subsequent call.  This section buffer will automatically be rendered upon a call
to render().

If the section is nested (i.e.) within the delimiters of another section then the parent buffer will be
appended to when that section is rendered and child buffer will be reset.

If this sounds confusing than see the example provided in the description
above.

Also the rendered section is return on a successful render_sec() call.

=head2 render

synopsis: B<$str = $trex_obj-E<gt>render( \%data_hsh, 'file_out_spec' )>

This renders the entire template.  If the second arguement is provided than a file will be written, if not
than output will be to standard out (or to the client in a cgi environment).  Also if desired the
output will be returned.

=head2 render_this

synopsis: B<$str = render_this( 'my_template', 'file_out_spec' )>

This is a function-oriented call that renders the entire template in one fell swoop.  As in the case
with the render() OO method this function outputs to a file if provided or to standard out if
no file_out_spec is provided. If you do not need sectional processing then this is the only function
call you.

Also the rendered section is return on a successful render_sec() call.


=head1 AUTHOR

Steve Troxel       troxelso@nswccd.navy.mil

=head1 BUGS

None known. Make reports to troxelso@nswccd.navy.mil

=head1 SEE ALSO

=head1 COPYRIGHT

2002/2003 Steve Troxel

=pod SCRIPT CATEGORIES




