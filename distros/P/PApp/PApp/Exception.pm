##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

PApp::Exception - exception handling for PApp

=head1 SYNOPSIS

 use PApp::Exception;

=head1 DESCRIPTION

This module implements a exception class that is able to carry backtrace
information and other information useful for tracking own bugs.

It's the standard exception class used by PApp.

=over 4

=cut

package PApp::Exception;

use base Exporter;
use overload ();

use PApp::HTML;

use utf8;

$VERSION = 2.2;
@EXPORT = qw(fancydie try catch);

no warnings;

# let's try to be careful, but brutale ausnahmefehler just rock!
sub __($) {
   eval { &PApp::__ } || $_[0];
}

use overload 
   'bool'   => sub { 1 },
   '""'     => sub { $_[0]{compatible} || $_[0]->as_string },
   fallback => 1,
   ;

=item local $SIG{__DIE__} = \&PApp::Exception::diehandler

_diehandler is a function suitable to be put into C<$SIG{__DIE__}> (e.g.
inside an eval). The advantage in using this function is that you get a
useful backtrace on an error (among some other information). It should be
compatible with any use of eval but might slow down evals that make heavy
use of exceptions (but these are slow anyway).

Example:

 eval {
    local $SIG{__DIE__} = \&PApp::Exception::diehandler;
    ...
 };

=cut

sub diehandler {
   unless (ref $_[0]) {
      # the next few lines are a major stability improvement, as well as a nice speedup
      return if $_[0] =~ m%in use at .*XML/Parser/Expat.pm line \d+\.$%;
      # better not touch utf8_heavy, since this is called at interesting times....
      return if $_[0] =~ m%.*at .*/utf8_heavy.pl line \d+\.$%;

      # wether compatible is a good idea here is questionable...
      fancydie(__"caught a die", $_[0], compatible => $_[0], skipcallers => 1);
   }
}

# internal utility function for Gimp::Fu and others
#      talking about code-reuse ^^^^^^^^ ;)
sub wrap_text {
   my $x;
   for (split /\n/, $_[0]) {
      s/\G(.{1,$_[1]})(?:\s+|$)/$1\n/gm;
      $x .= $_;
   }
   $x =~ s/[ \t\015]+$//g;
   $x;
}

# called by zero-argument "die"
sub PROPAGATE {
   push @{$_[0]{info}}, "propagated at $_[1] line $_[2]";
   $_[0];
}

=item $errobj = new PApp::Exception param => value..

Create and return a new exception object. The object is overloaded,
stringification will call C<as_string>.

 title      exception page title (default "PApp:Exception")
 body       the exception page body
 category   the error category
 error      the error message or error object
 info       additional info (arrayref)
 backtrace  optional backtrace info
 compatible if set, stringification will only return this field
 abridged   if set, only the error text will be shown
 as_string  if set, a plaintext instead of html will be generated

When called on an existing object, a clone of that exception object is
created and the information is extended (backtrace is being ignored,
title, info and error are extended).

=cut

sub new($$;$@) {
   my $class = shift;
   my %arg = @_;

   if (ref $class) {
      my %obj = %$class;

      $obj{backtrace} ||= delete $arg{backtrace};
      push @{$obj{info}}, @{delete $arg{info}};

      while (my ($k, $v) = each %arg) {
         $obj{$k} = $obj{$k} ? "$v\n$obj{$k}" : $v;
      }

      my ($i, $package, $filename, $line);
      do {
         $package, $filename, $line = caller $i++;
      } while ($package eq "PApp::Exception");

      push @{$obj{info}}, "propagated at $file line $line" if $package;

      bless \%obj, ref $class;
   } else {
      bless \%arg, $class;
   }
}

=item $errobj->throw

Throw the exception.

=cut

sub throw($) {
   die $_[0];
}

=item $errobj->as_string

Return the full exception information as simple text string.

=item $errobj->as_html

Return the full exception information as a fully formatted html page.

=cut

sub as_string {
   my $self = shift;
   local $@; # localize $@ as to not destroy it inadvertetly

   if ($self->{abridged}) {
      $self->{error};
   } else {
      my $err = "\n".($self->{title} || __"PApp::Exception caught")."\n\n$self->{category}\n";
      $err .= "\n$self->{error}\n" if $self->{error};
      if ($self->{info}) {
         for (@{$self->{info}}) {
            my $info = $_;
            my $desc;

            if (ref $info) {
               $desc = " ($info->[0])";
               $info = $info->[1];
            }

            $info = wrap_text $info, 80;
            $err .= "\n".__"Additional Info"."$desc:\n$info\n";
         }
      }
      $err .= "\n".__"Backtrace".":\n$self->{backtrace}\n";
      
      $err =~ s/^/! /gm;
      $err =~ s/\0/\\0/g;

      $err;
   }
}

sub title {
   $_[0]->{title} || __"PApp::Exception";
}

sub category {
   $_[0]->{category} || __"ERROR";
}

sub as_html {
   my $self = shift;

   if ($self->{abridged}) {
      my $category = escape_html $self->{category};
      my $error    = escape_html $self->{error};

      <<EOF;
<html>
<body>
<p><table bgcolor='#d0d0f0' cellspacing='0' cellpadding='10' border='0'>
<tr><td bgcolor='#b0b0d0'><font face='Arial, Helvetica' color='black'><b>$category</b></font></td></tr>
<tr><td><font color='#3333cc'>$error</font></td></tr>
</table></p>
</body>
</html>
EOF

   } else {
      my $title = sprintf __"%s (exception caught)", $self->title;

"<html>
<head>
<title>$title</title>
</head>
<body bgcolor=\"#d0d0d0\">
<blockquote>
<h1>$title</h1>".
      $self->_as_html(@_)."
</blockquote>
</body>
</html>";
   }
}

sub _as_html($;$) {
   my $self = shift;
   my %args = @_;
   my $title = $self->title;
   my $body  = $args{body}  || $self->{body}  || "";
   my $category = escape_html ($self->category);
   my $error = escape_html $self->{error};

   my $err = <<EOF;
<p><table bgcolor='#d0d0f0' cellspacing='0' cellpadding='10' border='0'>
<tr><td bgcolor='#b0b0d0'><font face='Arial, Helvetica'><b><pre>$category</pre></b></font></td></tr>
<tr><td><font color='#3333cc'>$error</font></td></tr>
</table></p>
EOF

   if ($self->{info}) {
      for (@{$self->{info}}) {
         my $info = $_;
         my $desc;

         if ("ARRAY" eq ref $info) {
            $desc = " ($info->[0])";
            $info = $info->[1];
         }

         $info = escape_html wrap_text $info, 80;
         $err .= "<p>
<table bgcolor='#e0e0e0' cellspacing='0' cellpadding='10' border='0'>
<tr><td bgcolor='#c0c0c0'><font face='Arial, Helvetica'><b>".__"Additional Info"."$desc:</b></font></td></tr>
<tr><td><pre>$info</pre></td></tr>
</table></p>
";
      }
   }

   if ($self->{backtrace}) {
      my $backtrace = escape_html $self->{backtrace};
      $err .= "<p>
<table bgcolor='#ffc0c0' cellspacing='0' cellpadding='10' border='0' width='94%'>
<tr><td bgcolor='#e09090'><font face='Arial, Helvetica'><b>".__"Backtrace".":</b></font></td></tr>
<tr><td><pre>$backtrace</pre></td></tr>
</table></p>
";
   }

   if ($body) {
      $body = wrap_text $body, 80;
      $err .= <<EOF;
<p><table bgcolor='#e0e0f0' cellspacing='0' cellpadding='10' border='0'>
<tr><td><pre>$body</pre></td></tr>
</table></p>
EOF
   }

   $err;
}

=item fancydie $category, $error, [param => value...]

Aborts the current page and displays a fancy error box, complete
with backtrace. C<$error> should be a short error message, while
C<$additional_info> can be a multi-line description of the problem.

The rest of the function call consists of named arguments that are
transparently passed to the PApp::Exception::new constructor (see above), with the exception of:

 skipcallers  the number of caller levels to skip in the backtrace

=item fancywarn <same arguments as fancydie>

Similar to C<fancydie>, but warns only. (not exported by default).

=cut

# almost directly copied from DB, since mod_perl + 5.6 + DB is just too fragile
# obviously, this is horrible code ;->
sub papp_backtrace {
  package DB;
  local $SIG{__DIE__};

  my $start = shift;
  my($p,$f,$l,$s,$h,$w,$e,$r,$a, @a, @ret,$i);
  $start = 1 unless $start;
  for ($i = $start; @DB::args = ("optimized away"), ($p,$f,$l,$s,$h,$w,$e,$r) = caller($i); $i++) {
    $f = "<commandline>" if $f eq "-e";
    $w = $w ? '@ = ' : '$ = ';
    if ($i > $start) {
       my @a = map {
          eval {
             if (tied $_) {
                "<<TIED ".(tied $_).">>";
             } elsif (ref) {
                if (overload::Overloaded $_) {
                   "<<OVERLOADED ".(overload::StrVal $_).">>";
                } else {
                   "$_";
                }
             } else {
                my $strval = "$_";
                $strval =~ s/'/\\'/g;
                $strval =~ s/([^\0]*)/'$1'/ unless /^-?[\d.]+$/;
                $strval =~ s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
                $strval =~ s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
                $strval;
             }
          } || do {
             $@ =~ s/ at \(.*$//s;
             $@;
          }
       } ($s eq "PApp::SQL::connect_cached"
          ? (@DB::args[0,1], "<user>", "<pass>", @DB::args[4,5]) # nur loeschwasser
          : @DB::args);
       $a = $h ? '(' . join(', ', @a) . ')' : '';
       $e =~ s/\n\s*\;\s*\Z// if $e;
       $e =~ s/[\\\']/\\$1/g if $e;
       if ($r) {
         $s = "require '$e'";
       } elsif (defined $r) {
         $s = "eval '$e'";
       } elsif ($s eq '(eval)') {
         $s = "eval {...}";
       }
    }
    push @ret, "$w$s$a\ncalled from $f line $l";
    last if $DB::signal;
  }
  return @ret;
}

sub _fancyerr {
   my $category = shift;
   my $error = shift;
   my $info = [];
   my $backtrace;
   my %arg;
   my $skipcallers = 2;

   my $class = PApp::Exception::;

   ($class, $error)    = ($error,     undef) if UNIVERSAL::isa $error,    PApp::Exception::;
   ($class, $category) = ($category,  undef) if UNIVERSAL::isa $category, PApp::Exception::;

   # fancydie is sometimes called with "foreign" exception objects (e.g. upcalls ;)
   die $error if ref $error;

   while (@_) {
      my $arg = shift;
      my $val = shift;
      if ($arg eq "skipcallers") {
         $skipcallers += $val;
      } elsif ($arg eq "info") {
         push @$info, $val;
      } else {
         $arg{$arg} = $val;
      }
   }

   unless (ref $class or $arg{abridged}) {
      for my $frame (papp_backtrace($skipcallers)) {
         $frame =~ s/  +/ /g;
         $frame = wrap_text $frame, 80;
         $frame =~ s/\n/\n    /g;
         $backtrace .= "$frame\n";
      }
   }

   s/\n+$//g for @$info;

   $class->new(
      ref $class ? () : (backtrace => $backtrace),
      category  => $category,
      error     => $error,
      info      => $info,
      %arg,
   );
}

sub fancydie {
   &_fancyerr->throw;
}

sub fancywarn {
   warn &_fancyerr;
}

=item vals = try BLOCK error, args...

C<eval> the given block (using a C<_diehandler>, C<@_> will contain
useless values and the context will always be array context). If no error
occurs, return, otherwise execute fancydie with the error message and the
rest of the arguments (unless they are C<catch>'ed).

=item catch BLOCK args...

Not yet implemented. If used as an argument to C<try>, execute the block
when an error occurs. Example:

   try {
      ... code
   } catch {
      ... code to be executed when an exception was raised
   };

=cut

sub try(&;$@) {
   my @r = eval {
      local $SIG{__DIE__} = \&diehandler;
      &{+shift};
   };
   if ($@) {
      die if UNIVERSAL::isa $@, PApp::Upcall::;
      my $err = shift;
      fancydie $err, $@, @_;
   }
   wantarray ? @r : $r[-1];
}

sub catch(&;%) {
   fancydie "catch not yet implemented";
}

=item $exc->errorpage

This method is being called by the PApp runtime whenever there is no handler
for it. It should (depending on the $PApp::onerr variable and others!) display
an error page for the user. Better overwrite the following methods, not this one.

=item $exc->ep_save

=item $html = $exc->ep_fullinfo

=item $html = $exc->ep_shortinfo

=item $html = $exc->ep_login

=item $html = $exc->ep_wrap(...)

Various parts of the error page that can be generated independently of the
others.

=cut

sub _clone {
   eval {
      local $SIG{__DIE__};
      require PApp::Storable; # should use Clone some day
      local $Storable::forgive_me = 1;
      PApp::Storable::dclone($_[0]);
   } || "$_[1]: $@";
}

sub _clone_request {
   my $r = $PApp::request;
   local $SIG{__DIE__};
   +{
      eval {
         time        => time,
         method      => $r->method,
         protocol    => $r->protocol,
         hostname    => $r->hostname,
         uri         => $r->uri,
         filename    => $r->filename,
         path_info   => $r->path_info,
         args        => $r->query_string,
         headers_in  => { $r->headers_in },
         remote_logname => $r->get_remote_logname,
         remote_addr => $r->connection->remote_addr,
         local_addr  => $r->connection->local_addr,
         http_user   => $r->connection->user,
         http_auth   => $r->connection->auth_type,
      }
   }
}

sub errorpage {
   package PApp;

   my $self = shift;
   my $onerr = exists $papp->{onerr} ? $papp->{onerr} : $PApp::onerr;
   my @html;

   $self->{save} = {
      misc      => {
         NOW       => $NOW,
         onerr     => $onerr,
      },

      state     => {
         arguments   => PApp::Exception::_clone(\%arguments, "unable to clone arguments"),
         params      => PApp::Exception::_clone(\%P,         "unable to clone params"),
         state       => PApp::Exception::_clone(\%state,     "unable to clone state"),
         userid      => $userid,
         sessionid   => $sessionid,
         stateid     => $stateid,
         prevstateid => $prevstateid,
         alternative => $alternative,
      },

      app       => {
         langs       => $langs,
      },

      output    => {
         content_type   => $content_type,
         output_charset => $output_charset,
         output_p       => $output_p,
         output         => $output,
         routput        => $$routput,
         doutput        => $doutput,
      },

      protocol => {
         location    => $location,
         pathinfo    => $pathinfo,
         request     => PApp::Exception::_clone_request,
      },
   };

   if ($self->{as_string}) {
      content_type("text/plain", "*");

      $PApp::output = $self->as_string;
   } else {
      content_type("text/html", "*");

      $onerr ||= "sha";

      push @html, $self->ep_save      if $onerr =~ /s/i;
      push @html, $self->ep_shortinfo if $onerr =~ /h/i;
      push @html, $self->ep_fullinfo  if $onerr =~ /v/i;
      push @html, $self->ep_login     if $onerr =~ /a/i;

      $PApp::output = $self->ep_wrap (@html);
   }
}

sub ep_save {
   my $self = shift;
   my $id;
   local $SIG{__DIE__};

   eval {
      require PApp::SQL;
      require PApp::Config;
      require Compress::LZF;

      $id = PApp::SQL::sql_insertid (
               PApp::SQL::sql_exec (
                  PApp::Config::DBH,
                  "insert into error values (NULL, NULL, ?, '')",
                  Compress::LZF::sfreeze_cr ($self)
               )
            );
   } || __"[unable to save error information: $@]";

   eval {
      require PApp::HTML;
      my $surl = $PApp::papp_main->surl("error", -set_comment => 1, -id => $id);

      my $output = "<form method='GET' action='$surl'>";
      $output .= sprintf __"saved as error report #%d", $id;

      $output .= "<br />".__"please enter a short description, this will help us fix the problem. thanks. ";
      $output .= "<br /><input type='text' name='comment' size='40' /> ";
      $output .= "</form>";
      $output .= "<hr /><a href='$surl'>".(__"[Login/View this error]")."</a>";

      $output;
   } || __"[unable to enter error browser: $@]";
}

sub ep_shortinfo {
   my $self = shift;
   $self->category;
}

sub ep_fullinfo {
   my $self = shift;
   $self->_as_html;
}

sub ep_login {
   my $self = shift;
   local $SIG{__DIE__};
   eval {
      $PApp::papp_main->slink(__"[Login/View this error]", "error", -exception => $self);
   } or __"[unable to enter error browser at this time]";
}

sub ep_wrap {
   my $self = shift;
   my $title = sprintf __"%s (exception caught)", $self->title;
   "<html>
    <head>
    <title>$title</title>
    </head>
    <body bgcolor=\"#d0d0d0\">
    <blockquote>
    <h1>$title</h1>".
   (join "", map "<p>$_</p>", @_).
   "</blockquote></body></html>";
}

1;

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

