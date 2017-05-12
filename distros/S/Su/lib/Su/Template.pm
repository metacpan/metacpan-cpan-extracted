package Su::Template;

use strict;
use warnings;
use Exporter;

use File::Path;
use Data::Dumper;
use Test::More;
use Carp;
use Fatal qw(open close);

use Su::Log;

our @ISA = qw(Exporter);

# render requires explicit use declaration.
our @EXPORT    = qw(expand);
our @EXPORT_OK = qw(render);

our $DEBUG = 0;

# not used.
my $MODULE_PATH = __FILE__;

# not used.
our $TEMPLATE_BASE_DIR = "./";

# not used.
our $TEMPLATE_DIR = "Templates";

=pod

=head1 NAME

Su::Template - A module to make the string using the specified template and passed parameters.

=head1 SYNOPSIS

 my $tmpl = Su::Template->new;
 my $str = $tmpl->expand( <<'HERE', $arg);
 % my $arg = shift;
 arg is <%=$arg%>
 HERE

=head1 DESCRIPTION

Su::Template is a module to make the string using the specified template and passed parameters.

=head1 AUTHOR

lottz <lottzaddr@gmail.com>

=head1 FUNCTIONS

=over

=cut

=item new()

A constructor.

=cut

sub new {
  my $self = shift;

  my %h = @_ if @_;
  my $log = Su::Log->new;
  $h{logger} = $log;
  return bless \%h, $self;
} ## end sub new

sub import {
  my $self = shift;

  # Save import list and remove from hash.
  my %tmp_h = @_ if @_;
  my $imports_aref = $tmp_h{import};
  delete $tmp_h{import};
  my $base = $tmp_h{base};
  my $dir  = $tmp_h{dir};
  Su::Log->trace( "base:" . Dumper($base) );
  Su::Log->trace( "dir:" . Dumper($dir) );

  #  print "base:" . Dumper($base) . "\n";
  #  print "dir:" . Dumper($dir) . "\n";

  $TEMPLATE_BASE_DIR = $base if $base;
  $TEMPLATE_DIR      = $dir  if $dir;

  if ( $base || $dir ) {
    $self->export_to_level( 1, $self, @{$imports_aref} );
  } else {

# If 'base' or 'dir' is not passed, then all of the parameters are required method names.
    $self->export_to_level( 1, $self, @_ );
  }

} ## end sub import

=item expand()

Expand the template using the passed context and return the result string.
Note that the keyword for here document must quoted by single quote. Double quote should cause unexpected error.

Template syntax:

 <%= $val %> render the variable. Html special character will escaped.
 <%== $val %> render the variable. Html special character will not escaped.
 End tag ~%> discards line separator.
 Expression surrounded by <% %> or the line start with '%' will parsed as Perl statements.

If you want debug output, set the following flag on,  then expand method return the debug string.

 $Su::Template::DEBUG=1;

The functional style usage of this method is the following.

 $ret = Su::Template::expand(<<'__HERE__');
 <% foreach my $v ("aa","bb","cc"){~%>
 <%= $v%>
 <%}~%>
 xxx
 yyy
 zzz
 __HERE__

The OO style usage of this method is the following.

 my $tmpl = Su::Template->new;
 my $str = $tmpl->expand( <<'HERE', $title, $link );
 % my $title = shift;
 % my $link = shift;
 <a href="<%=$link%>"><%=$title%></a>
 HERE

The html special character in variable expression will be escaped like the following.

 $ret = $t->expand( <<'__HERE__', "aa<bb>cc'dd\"ee&ff" );
 % my $arg = shift;
 <%= $arg ~%>
 __HERE__

 is( $ret, "aa&lt;bb&gt;cc&apos;dd&quot;ee&amp;ff" );

Note that the html special character described in the raw part of the template will not be escaped.

=cut

my $escape_hash_str =
"my %escape_h = (  '<'  => '&lt;',  '>'  => '&gt;',  '\"'  => '&quot;',  \"'\", => '&apos;',  '&'  => '&amp;',);";

sub expand {
  no warnings qw(redefine);

  # TODO: If the pushed data to the list @f_t_a is a empty strng, then
  #       we should remove this process to simplify and optimize the
  #       method `make_template`.  But whether add "\n" or not is rather
  #       complex, so optimization is a put-offed task.
  my $self = shift if ( ref $_[0] eq __PACKAGE__ );
  my $DEBUG = $self->{debug} ? $self->{debug} : $DEBUG;

  my $org                = shift;
  my @args               = @_;
  my @ret                = "";
  my $b_perl_mode        = 0;
  my $b_no_last_newline  = 0;
  my $b_need_escape_hash = 0;
  my $b_need_tmp_val     = 0;

# add dumy \n prepare for after pop. And set flag not to add \n the end of the line.
  if ( substr( $org, ( length $org ) - 1 ) ne "\n" ) {
    $org .= "\n";
    $b_no_last_newline = 1;
  }

  my @lines = split "\n", $org, -1;
  pop @lines;
  my $line_num      = scalar @lines;
  my $current_line  = 0;
  my $candidate_str = '';
  Su::Log->trace( "org:" . Dumper($org) );
  for my $l (@lines) {
    Su::Log->trace( "loop:" . $l );
    ++$current_line;
    my $b_match            = 0;
    my $b_need_line_return = 1;
    if ( $b_perl_mode && $l =~ /(.*)%>(\s*)$/ ) {
      $b_perl_mode        = 0;
      $b_match            = 1;
      $b_need_line_return = 0;
      push @ret, $1;
      Su::Log->trace("perl mode out");
    } elsif ($b_perl_mode) {
      Su::Log->trace("is perl mode");
      $b_match            = 1;
      $b_need_line_return = 0;
      push @ret, $l;
    } elsif ( substr( $l, 0, 1 ) eq '%' ) {
      push @ret, substr( $l, 1 );
      $b_match            = 1;
      $b_need_line_return = 0;
    } elsif ( $l =~ /^\s*<%(.*)/ && index( $l, "%>" ) == -1 ) {
      $b_perl_mode        = 1;
      $b_need_line_return = 0;
      $b_match            = 1;
      push @ret, $1;
      Su::Log->trace("perl mode in");
    } else {
      my $prev_pos = 0;
      while ( $l =~ /<%((={0,2})(.*?)([~])?)%>/g ) {
        $b_match = 1;

   #      push @ret, ('push(@f_t_a, \'' . $`. '\');') if $`; # add previous part
        my $tmp = $-[0];

        $candidate_str = substr( $l, $prev_pos, $tmp - $prev_pos );

        #note: Ensure matched varibe like $1 not effect outer scope.
        {
          $candidate_str =~ s/'/\\'/g if defined $candidate_str;
        }
        $candidate_str && push @ret,
          ( 'push(@f_t_a, \'' . $candidate_str . '\');' )
          ;    # save from previous end pos to current start pos.
        if ( defined $2 && ( $2 eq '=' or $2 eq '==' ) )
        {      # print variable itself
          my $exp = $3;

          $b_need_tmp_val = 1;
          if ( $2 eq '=' ) {
            $b_need_escape_hash = 1;
          }

          {
            $exp =~ s/^ *(.*?) *$/$1/;    # trim front and end of white space.
          }

#        push @ret, ('push(@f_t_a, (' . $exp . '));'); # NOTE: other variables may be double quote not single quote like this like.

          # Escape and push.
          if ( $2 eq '=' ) {
            push @ret, '$tmp_val = ' . '(' . $exp . ');';

# If the special charactor is already escaped using '&', then prevent unexpected double escaped.
            push @ret, 'if($tmp_val){
                            $tmp_val=~s/&(?!(lt|gt|amp|quot|apos);)/&amp;/go;
                            $tmp_val=~s/(<|>|\'|")/$escape_h{$1}/go;';

            # $tmp_val=~s/(<|>|\'|"|&)/$escape_h{$1}/go;';
            push @ret, ( 'push(@f_t_a, $tmp_val' . ');}' );
            push @ret, ('elsif(defined $tmp_val){push(@f_t_a, $tmp_val);}');
          } else {

            # Push only. Not escape.
            push @ret, '$tmp_val = ' . '(' . $exp . ');';
            push @ret, 'if($tmp_val){';
            push @ret, ( 'push(@f_t_a, $tmp_val' . ');}' );
            push @ret, ('elsif(defined $tmp_val){push(@f_t_a, $tmp_val);}');

          } ## end else [ if ( $2 eq '=' ) ]

        } else {
          push @ret, $3;
        }
        $prev_pos = pos($l);

        $b_need_line_return = 0 if ( defined $4 && $4 eq '~' );
      }    #while match

# If match, register tail part. If not this condition, <% %>not include line will  retisterred twice!
      if ($b_match) {
        $candidate_str = substr( $l, $prev_pos, ( length $l ) - $prev_pos );

        #note: Ensure matched varibe like $1 not effect outer scope.
        {
          $candidate_str =~ s/'/\\'/g if defined $candidate_str;
        }
        $candidate_str && push @ret,
          ( 'push(@f_t_a, \'' . $candidate_str . '\');' )
          ;    # save to the tail of the line.
      } ## end if ($b_match)
    }    # else end

    my $no_need_newline = ( $line_num == $current_line ) && $b_no_last_newline;

# Add new line to the make_template function itself. If the current line is comment, then we need new line to add \n to the @f_t_a array.
    push @ret, "\n";

    if ($b_match) {
      Su::Log->trace("line b_match");

#      push @ret, ('push(@f_t_a, \'' . (($b_need_line_return && !$b_no_newline) ? "\n" : '') . '\');');# print eol.
      push @ret,
        (   'push(@f_t_a, \''
          . ( ( $b_need_line_return && !$no_need_newline ) ? "\n" : '' )
          . '\');' );    # print eol.
    } else {
      Su::Log->trace("line not b_match");
      $l =~ s/'/\\'/g;

#      push @ret, ('push(@f_t_a, \'' . $l. (($b_need_line_return && !$b_no_newline) ? "\n" : '') . '\');');#print whole line.
      if ( !$b_need_line_return || $no_need_newline ) {
        $l && push @ret, ( 'push(@f_t_a, \'' . $l . '\');' );
      } else {

        #print whole line.
        push @ret, ( 'push(@f_t_a, \'' . $l . "\n" . '\');' );
      }
    } ## end else [ if ($b_match) ]

    #    push @ret, "\n";
  }    #while line

  unshift( @ret, 'my $tmp_val="";' . "\n" )
    if $b_need_tmp_val;
  unshift( @ret, $escape_hash_str . "\n" )
    if $b_need_escape_hash;

  unshift( @ret, 'sub make_template{' . "\n" . 'my @f_t_a=();' . "\n" );
  push( @ret, 'return join(\'\',@f_t_a);' . "\n" . '}' );
  my $prepare_data = join( '', @ret );
  eval($prepare_data);
  $@ and die "[ERROR]Invalid Template format:" . $@ . "\n" . $prepare_data;

  if ($DEBUG) {
    return $prepare_data;    # return pre-eval data.
  } else {
    return make_template(@args);    # call evaled method.
  }
}    # eos expand()

=item render()

An alias to the method L<expand>.

=cut

sub render {
  return expand(@_);
}

=pod

=back

=cut

1;

