package VCP::Dest::revml ;

=head1 NAME

VCP::Dest::revml - Outputs versioned files to a revml file

=head1 SYNOPSIS

   revml:[<output-file>]
   revml:[<output-file>] --dtd <revml.dtd>
   revml:[<output-file>] --version <version>
   revml:[<output-file>] --compress
   revml:[<output-file>] --no-indent

=head1 DESCRIPTION

The --dtd and --version options cause the output to be checked against
a particular version of revml.  This does I<not> cause output to be in 
that version, but makes sure that output is compliant with that version.

Using the --compress option generates a gzipped revml file as output.

If the output filename ends in ".gz", the output will be compressed 
even if the --compress flag isn't present.

The --no-indent option makes the revml output with all the start tags
flush left rather than indented to indicate the tree structure.

=head1 EXTERNAL METHODS

=over

=cut

use VCP::Logger qw( pr );

BEGIN {
   ## Beginning vcpers might try running a command like "vcp" just
   ## to see what happens.  Since RevML is not required for most
   ## vcp uses and XML::Parser requires a C compiler, vcp is often
   ## distributed without XML::Parser, so this message is to help
   ## steer hapless new users to the help system if the XML output
   ## modules are also not found.

   ## The exit(1) is to avoid untidy and scary 
   ## "compilation failed in BEGIN" messages
   pr( <<TOHERE ), exit 1 unless eval "require RevML::Writer";
RevML::Writer is not installed or loading properly on this system and
it is required to write RevML files.  If writing RevML files is not
what you want to do, try

    vcp help

TOHERE
}


use strict ;

use Carp ;
use Digest::MD5 ;
use Fcntl ;
use MIME::Base64 ;
use RevML::Doctype ;
use RevML::Writer ;
use Symbol ;
use UNIVERSAL qw( isa ) ;
use VCP::Debug qw( :debug ) ;
use VCP::Logger qw( lg );
use VCP::Rev qw( iso8601format );
use VCP::Utils qw( shell_quote empty );

use Text::Diff ;

use vars qw( $VERSION ) ;

$VERSION = 0.1 ;

use base 'VCP::Dest' ;

use fields (
   'OUT_FH',    ## The handle of the output file
   'WRITER',    ## The XML::AutoWriter instance write with
   'SEEN_REV',  ## Whether we've seen our first revision or not.
   'NO_INDENT', ## output all flush left, not indented to indicate tree structure
) ;


=item new

Creates a new instance.  The only parameter is '-dtd', which overrides
the default DTD found by searching for modules matching RevML::DTD:v*.pm.

Attempts to create the output file if one is specified.

=cut

sub new {
   my $class = shift ;
   $class = ref $class || $class ;

   my VCP::Dest::revml $self = $class->SUPER::new( @_ ) ;

   my @errors ;

   my ( $spec, $options ) = @_ ;

   $self->parse_repo_spec( $spec ) ;

   $self->repo_id(
      join ":",
         "revml",
         defined $self->repo_server   ? $self->repo_server   : "",
         defined $self->repo_filespec ? $self->repo_filespec : "",
   );

   my $doctype;

   $self->parse_options(
      $options,
      'dtd|version' => sub {
         $doctype = RevML::Doctype->new( shift @$options ) ;
      },
      "compress"          => \my $compress,
      "no-indent"         => \$self->{NO_INDENT},
   );

   $self->head_revs->open_db;

   $doctype = RevML::Doctype->new
      unless $doctype ;

   my $file_name = $self->repo_filespec;
   $file_name = "-" if empty $file_name;

   # always un-compress if filename ends in ".gz"
   my $gzip;
   if ( $^O =~ /Win32/ ) {
      $compress = 1 if $file_name =~ /\.gz$/i ;
      $gzip = "gzip.exe";
   }
   else {
      $compress = 1 if $file_name =~ /\.gz$/ ;
      $gzip = "gzip";
   }

   if ( $file_name eq '-' ) {
      if( $compress ) {
         require Symbol ;
         $self->{OUT_FH} = Symbol::gensym ;
         open( $self->{OUT_FH}, "| $gzip" )
            or die "$!: | gzip" ;
      }
      else {
         $self->{OUT_FH}   = \*STDOUT ;
      }
      ## TODO: Check OUT_FH for writability when it's set to STDOUT
   }
   else {
      require Symbol ;
      $self->{OUT_FH} = Symbol::gensym ;
      ## TODO: Provide a '-f' force option

      if( $compress ) {
         my $out_name = shell_quote $file_name;
         open( $self->{OUT_FH}, "| $gzip > $out_name" )
            or die "$!: | gzip > $file_name" ;
      }
      else {
         open( $self->{OUT_FH}, ">$file_name" ) or die "$!: '$file_name'" ;
      }
   }
   ## BUG: Can't undo this AFAIK, so we're permanently altering STDOUT
   ## if $out_name eq '-'.
   binmode $self->{OUT_FH};

lg "revml going to ", fileno $self->{OUT_FH};

   die join( '', @errors ) if @errors ;

   $self->writer(
      RevML::Writer->new(
	 DOCTYPE => $doctype,
	 OUTPUT  => $self->{OUT_FH},
      )
   );

   return $self ;
}


sub _emit_characters {
   my ( $w, $buf ) = @_ ;

   $w->setDataMode( 0 ) ;

   ## Note that we don't let XML munge \r to be \n!!
   while ( $$buf =~ m{\G(?:
      (   [\x00-\x08\x0b-\x1f\x7f-\xff])
      | ([^\x00-\x08\x0b-\x1f\x7f-\xff]*)
      )}gx
   ) {
      if ( defined $1 ) {
	 $w->char( "", code => sprintf( "0x%02x", ord $1 ) ) ;
      }
      else {
	 $w->characters( $2 ) ;
      }
   }

}


sub handle_rev {
   my VCP::Dest::revml $self = shift ;
   my VCP::Rev $r ;
   ( $r ) = @_ ;

   my $w = $self->writer ;

   if ( ! $self->{SEEN_REV} ) {
      ## We don't write any XML until the first rev arrives, so an empty
      ## RevML input doc (with root node but no revs) results in no output.
      ## This is more for non-RevML inputs, so that an export that selects
      ## no new revisions generates no output, which is easy to test for.
      $w->setDataMode( 1 ) unless $self->{NO_INDENT};
      $w->xmlDecl ;
      my $h = $self->header ;
      ## VCP::Source::revml passes through the original date.  Other sources
      ## don't.
      $w->time(
         defined $h->{time}
	    ? iso8601format $h->{time}
	    : iso8601format gmtime
      ) ;
      $w->rep_type( $h->{rep_type} ) ;
      $w->rep_desc( $h->{rep_desc} ) ;
      $w->comment(   $h->{comment}    ) if defined $h->{comment};
      $w->rev_root( $h->{rev_root} ) ;
      if ( $h->{branches} && $h->{branches}->get ) {
         $w->start_branches;
         for my $branch ( $h->{branches}->get ) {
            $w->start_branch;
            for ( qw( branch_id dest_branch_id ) ) {
               $w->$_( $branch->$_ || "" );
            }
            for ( qw( p4_branch_spec ) ) {
               my $s = $branch->$_;
               $w->$_( $s ) unless empty $s;
            }
            $w->end_branch;
         }
         $w->end_branches;
      }
   }

   $self->{SEEN_REV} = 1;

   ## TODO: get rid of revs that aren't needed.  We should only need
   ## the most recent rev with a work path on each branch.

   my $fn = $r->name ;

   my $is_base_rev = $r->is_base_rev ;

   ## type and rev_id are not provided for VSS deletes
   debug "emitting revml for ", $r->as_string
      if debugging;

   eval {
      $w->start_rev( id => $r->id );
      $w->name(                 $fn                      );
      $w->source_name(          $r->source_name          );
      $w->source_filebranch_id( $r->source_filebranch_id );
      $w->source_repo_id(       $r->source_repo_id );
      $w->type(       $r->type               ) if defined $r->type ;
      $w->p4_info(    $r->p4_info            ) if defined $r->p4_info ;
      $w->cvs_info(   $r->cvs_info           ) if defined $r->cvs_info ;

      if( defined $r->branch_id || defined $r->source_branch_id ) {
         $w->branch_id(
            defined $r->branch_id        ? $r->branch_id        : ()
         );
         $w->source_branch_id(
            defined $r->source_branch_id ? $r->source_branch_id : ()
         );
      }

      $w->rev_id(                   $r->rev_id ) if defined $r->rev_id ;
      $w->source_rev_id(     $r->source_rev_id ) if defined $r->source_rev_id ;

      if( defined $r->change_id || defined $r->source_change_id ) {
         $w->change_id(
            defined $r->change_id        ? $r->change_id        : ()
         );
         $w->source_change_id(
            defined $r->source_change_id ? $r->source_change_id : ()
         );
      }

      $w->time(       iso8601format $r->time )     if defined $r->time ;
      $w->mod_time(   iso8601format $r->mod_time ) if defined $r->mod_time ;
      $w->user_id(    $r->user_id            )     if defined $r->user_id;

      ## Sorted for readability & testability
      $w->label( $_ ) for sort $r->labels ;

      unless ( empty $r->comment ) {
         $w->start_comment ;
         my $c = $r->comment ;
         _emit_characters( $w, \$c ) ;
         $w->end_comment ;
         $w->setDataMode( 1 ) unless $self->{NO_INDENT};
      }

      $w->previous_id( $r->previous_id ) if defined $r->previous_id;

      my $convert_crs = $^O =~ /Win32/ && ( $r->type || "" ) eq "text" ;

      my $digestion ;
      my $close_it ;
      my $cp;
      ( $cp ) = VCP::Revs->fetch_files( $r )
         if $is_base_rev || $r->action eq "add" || $r->action eq "edit" || $r->action eq "branch";

      if ( $is_base_rev ) {
         sysopen( F, $cp, O_RDONLY ) or die "$!: $cp\n" ;
         binmode F ;
         $digestion = 1 ;
         $close_it = 1 ;
      }
      elsif ( $r->is_placeholder_rev ) {
         $w->placeholder() ;
         $digestion = 0;
      }
      elsif ( $r->action eq 'delete' ) {
         $w->delete() ;
      }
      else {
         sysopen( F, $cp, O_RDONLY ) or die "$!: $cp\n" ;
         ## need to binmode it so ^Z can pass through, need to do \r and
         ## \r\n -> \n conversion ourselves.
         binmode F ;
         $close_it = 1 ;

         my $buf ;
         my $read ;
         my $has_nul ;
         my $total_char_count = 0 ;
         my $bin_char_count   = 0 ;
         while ( ! $has_nul ) {
            $read = sysread( F, $buf, 100_000 ) ;
            die "$! reading $cp\n" unless defined $read ;
            last unless $read ;
            $has_nul = $buf =~ tr/\x00// ;
            $bin_char_count   += $buf =~ tr/\x00-\x08\x0b-\x1f\x7f-\xff// ;
            $total_char_count += length $buf ;
         } ;

         sysseek( F, 0, 0 ) or die "$! seeking on $cp\n" ;
         
         $buf = '' unless $read ;
         ## base64 generate 77 chars (including the newline) for every 57 chars
         ## of input. A '<char code="0x01" />' element is 20 chars.
         my $encoding = $bin_char_count * 20 > $total_char_count * 77/57
            ? "base64"
            : "none" ;

         my $pr = $r->previous;
         $pr = $pr->previous if $pr && ( $pr->action || "" ) eq "placeholder";

         if ( $pr                       ## Can't delta unless we have $pr
            && defined $pr->work_path
            && $encoding eq "none"      ## base64, should't delta.
         ) {
            $w->start_delta( type => 'diff-u', encoding => 'none' ) ;

            my $old_cp = $pr->work_path ;

            die "no old work path for '", $pr->id, "'\n"
               if empty $old_cp ;

            die "old work path '$old_cp' not found for '", $pr->id, "'\n"
               unless -f $old_cp ;

            ## TODO: Include entire contents if diff is larger than the contents.

            ## Accumulate a bunch of output so that characters can make a
            ## knowledgable CDATA vs &lt;&amp; escaping decision.
            my @output ;
            my $outlen = 0 ;
            my $delete_nl ;
            ## TODO: Write a "minimal" diff output handler that doesn't
            ## emit any lines from $old_cp, since they are redundant.
            debug "diffing $old_cp $cp" if debugging;
            diff $old_cp, $cp,
               {
                  ## Not passing file names, so no filename header.
                  STYLE  => "VCP::DiffFormat",
                  OUTPUT => sub {
                     push @output, $_[0] ;
                     ## Assume no lines split between \r and \n because
                     ## diff() splits based on lines, so we can just
                     ## do a simple conversion here.
                     $output[-1] =~ s/\r\n|\r/\n/g if $convert_crs ;
                     $outlen += length $_[0] ;
                     return unless $outlen > 100_000 ;
                     _emit_characters( $w, \join "", splice @output  ) ;
                  },
               } ;
            _emit_characters( $w, \join "", splice @output  ) if $outlen ;
            $w->end_delta ;
            $w->setDataMode( 1 ) unless $self->{NO_INDENT};
         }
         else {
            ## Full content, no delta.
            $w->start_content( encoding => $encoding ) ;
            my $delete_nl ;
            while () {
               ## Odd chunk size is because base64 is most concise with
               ## chunk sizes a multiple of 57 bytes long.
               $read = sysread( F, $buf, 57_000 ) ;
               die "$! reading $cp\n" unless defined $read ;
               last unless $read ;
               if ( $convert_crs ) {
                  substr( $buf, 0, 1 ) = ""
                     if $delete_nl && substr( $buf, 0, 1 ) eq "\n" ;
                  $delete_nl = substr( $buf, -1 ) eq "\n" ;
                  $buf =~ s/(\r\n|\r)/\n/g ;  ## ouch, that's gotta hurt.
               }
               if ( $encoding eq "none" ) {
                  _emit_characters( $w, \$buf ) ;
               }
               else {
                  $w->characters( encode_base64( $buf ) ) ;
               }
            }
            $w->end_content ;
            $w->setDataMode( 1 ) unless $self->{NO_INDENT};
         } ;
         $digestion = 1 ;
      }

      if ( $digestion ) {
         ## TODO: See if this should be seek or sysseek.
         sysseek F, 0, 0 or die "$!: $cp" ;
         my $d= Digest::MD5->new ;
         ## gotta do this by hand, since it's in binmode and we want
         ## to handle ^Z and lone \r's.
         my $delete_nl ;
         my $read ;
         my $buf ;
         while () {
            $read = sysread( F, $buf, 10_000 ) ;
            die "$! reading $cp\n" unless defined $read ;
            last unless $read ;
            if ( $convert_crs ) {
               substr( $buf, 0, 1 ) = ""
                  if $delete_nl && substr( $buf, 0, 1 ) eq "\n" ;
               $delete_nl = substr( $buf, -1 ) eq "\n" ;
               $buf =~ s/(\r\n|\r)/\n/g ;  ## ouch, that's gotta hurt.
            }
            $d->add( $buf ) ;
         }
         $d->addfile( \*F ) ;
         $w->digest( $d->b64digest, type => 'MD5', encoding => 'base64' ) ;
      }
      if ( $close_it ) {
         close F ;
      }

      $w->end_rev ;
      1;
   } or die "$@ while writing ", defined $r ? $r->as_string : "UNDEF $r!!";


   ## This frees up any previous revs that are no longer needed.  We only
   ## need previous revs if there is no file associated with this rev.
   $r->previous( undef )
      if defined $r->work_path && ( $r->action || "" ) ne "placeholder";

   $self->head_revs->set( [ $r->source_repo_id, $r->source_filebranch_id ],
                          $r->source_rev_id );
}


sub handle_footer {
   my VCP::Dest::revml $self = shift ;
   my ( $footer ) = @_ ;

   $self->writer->endAllTags() if $self->{SEEN_REV};

   $self->{SEEN_REV} = 0;

   return ;
}


sub writer {
   my VCP::Dest::revml $self = shift ;
   $self->{WRITER} = shift if @_ ;
   return $self->{WRITER} ;
}


=back

=head1 AUTHOR

Barrie Slaymaker <barries@slaysys.com>

=head1 COPYRIGHT

Copyright (c) 2000, 2001, 2002 Perforce Software, Inc.
All rights reserved.

See L<VCP::License|VCP::License> (C<vcp help license>) for the terms of use.

=cut

1
