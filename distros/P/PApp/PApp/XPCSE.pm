package PApp::XPCSE;

use HTTP::Date;

use common::sense;

use PApp;
use PApp::Exception;
use PApp::MimeType;
use PApp::Callback;
use PApp::HTML;

use Exporter "import";

our @EXPORT = qw(
   remote_edit_parse
   remote_edit_store
   client_edit_surl
   client_edit_slink
);

sub remote_edit_parse {
   my $buf;
   $request->read($buf, $request->header_in ("Content-Length"));
   if ($request->header_in ("Content-Type") =~ /^text\//) {
        Convert::Scalar::utf8_valid $buf or die "format violation - only utf8 supported\n";
        Convert::Scalar::utf8_on $buf;

        # remove byte-order-mark, as per unicode 3, section 13.6
        $buf =~ y/\x{feff}//d;
   }
   $buf
}

sub remote_edit_store {
   my ($fh) = @_;
   my $buf;
   my $len = $request->header_in ("Content-Length");
   while($len) {
      my $rlen = ($len > 8192) ? 8192 : $len;
      $request->read($buf, $rlen);
      print $fh $buf;
      $len -= $rlen;
   }
}

our $remote_edit = register_callback {
   my ($data, $mode) = @_;

   my %flags = %{$data->{flags}};

   abort_with {
      eval {
         if ($mode) {
            $P{pver} >= 1 && $P{pver} < 2
               or die "unsupported xpcse protocol version\n";

            for my $c (qw(pver command ostype)) {
               die "Required header \"$c\" missing\n" unless exists $P{$c};
            }
            if ($P{command} eq "store") {
               if (exists $data->{file}) {
                  my $dest = $data->{file};
                  open my $fh, ">", "$dest.$$" or die "open $dest.$$";
                  remote_edit_store($fh);
                  close $fh;
                  rename "$dest.$$", $dest or die "can't rename to $dest";
               } else {
                  my $x = &remote_edit_parse;
                  $x =~ s/\015\012/\012/g if $data->{mime} =~ m@^text/@ && $P{ostype} eq "win";
                  ${$data->{ref}} = $x;
               }
               content_type "text/plain";
               $request->status(200);
               echo "upload ok";
               if ($PApp::warn_log) {
                  echo ", but the following warnings were logged:\n\n$PApp::warn_log";
               }
            } elsif ($P{command} eq "fetch") {
               abort_with { 
                  if(exists $data->{file}) {
                     use PApp qw(abort_with_file);
                     my $file = $data->{file};
                     if (!-e $file && exists $data->{flags}{template}) {
                        $file = $data->{flags}{template};
                     }
                     open my $fh, "<", $file or die "can't open $file";
                     abort_with_file $fh, $data->{mime};
                  } elsif ($data->{mime} =~ m@^text/@) {
                     content_type $data->{mime}, "utf-8";
                     my $out = "${$data->{ref}}";
                     $out =~ s/\012/\015\012/g if $P{ostype} eq "win";
                     echo $out;
                  } else {
                     content_type $data->{mime};
                     echo ${$data->{ref}};
                  }
               };
            } else {
               die "illegal command specified.";
            }
         } else {
            my %outflags;
            $outflags{"Extension"}              = $flags{extension}
                                                  || ("." . (PApp::MimeType::by_mimetype($data->{mime})
                                                             or PApp::MimeType::by_mimetype("application/octet-stream"))->extension);
            $outflags{"Url"}                    = $data->{url};
            $outflags{"Content-Type"}           = $data->{mime};
            $outflags{"Server-Date"}            = time2str();
            $outflags{"Xpcse-Protocol-Version"} = "1.1";
            $outflags{"Quiet"}                  = $flags{quiet} if exists $flags{quiet};
            $outflags{"On-Exit-Only"}           = $flags{on_exit_only} if exists $flags{on_exit_only};
            $outflags{"Check-Ms"}               = $flags{check_ms} if exists $flags{check_ms};
            $outflags{"Dirty-Wait"}             = $flags{dirty_wait} if exists $flags{dirty_wait};
            $outflags{"Auth-Username"}          = $flags{auth_username} if exists $flags{auth_username};
            $outflags{"Auth-Password"}          = $flags{auth_password} if exists $flags{auth_password};
            $outflags{"Auth-Proxy-Username"}    = $flags{auth_proxy_username} if exists $flags{auth_proxy_username};
            $outflags{"Auth-Proxy-Password"}    = $flags{auth_proxy_password} if exists $flags{auth_proxy_password};
            $outflags{"Line"}                   = $flags{line} if exists $flags{line};

            my $outflags;
            while (my ($x,$y) = each %outflags) {
               $x =~ s/[ \t:\012\015]//g;
               $outflags .= "$x: $y\015\012";
            }

            content_type "application/x-xpcse", "utf-8";
            $request->header_out("Content-Disposition" => "inline; filename=x.xpcse"); # for windows (file extension!)
            echo "$outflags\015\012";
         }
      };

      fancydie "xpcse upload error", $@, as_string => 1
         if $@;
   }
} name => "papp_xpcse_rep";

sub client_edit_surl {
   my ($ref, $mime, %flags) = @_;

   $mime = PApp::MimeType::by_extension $flags{extension} if !defined $mime && $flags{extension};
   $mime = (PApp::MimeType::by_filename $ref)->mimetype if !defined $mime && !ref $ref;

   my $data = {
      (ref $ref) ? (ref => $ref) : (file => $ref),
      mime  => $mime,
      flags => { %flags },
   };

   my ($url, $key) = surl SURL_STYLE_STATIC, $remote_edit->refer ($data, 1);

   if (defined $PApp::papp->{xpcse_prefix}) {
      $url = $PApp::papp->{xpcse_prefix};
   } elsif (length $request->header_in ("Host")) {
      $url = "http://"
           . $request->header_in ("Host")
           . $url;
   } else {
      $url = "http://"
           . $request->hostname
           . ":" . $request->get_server_port
           . $url;
   }

   $data->{url} = "$url/$key";

   surl $remote_edit->refer ($data, 0);
}

sub client_edit_slink {
   my ($content, $ref, $mime, %flags) = @_;

   alink $content, client_edit_surl $ref, $mime, %flags;
}

=head1 CONFIG OPTIONS

The papp app config variable C<xpcse_prefix> can be used to specify an
access port that xpcse uses. This is useful in case the application itself
is protected by basic authentication or cookies and xpcse cannot make use
of them.

=head1 FUNCTIONS

=over 4

=item client_edit_surl $ref, $content-type, %flags

Returns a surl for remote editing ref

  $ref            A tied scalar that should be edited or a fully
                  qualified filename
  $content-type   Content-type like "image/jpg"
  @flags          Optional flags that affects processing.
                  Supported flags:

                      extension => ".png"
                        file extension like ".txt". If missing, a
                        suitable extension will be guessed (see
                        LIBDIR/etc/xpcse.extensions).

                      check_ms => 300
                        check interval for filesystem updates

		      dirty_wait => 2
                        mtime must be stable for dirty_wait check_ms
                        rounds before submitting

                      on_exit_only => 1
                        save only when client-app is exiting

                      quiet => 1
                        suppress "Upload OK messages"

                      template => "/path/to/templatefile" 
                        substitute this file if $ref is a filename
                        that does not exist. Copy on write

                      auth_username => "username"
                        username for http authentification

                      auth_password => "password"
                        password for http authentification
                        
                      auth_proxy_username => "username"
                        username for proxy authentification

                      auth_proxy_password => "password"
                        password for proxy authentification

                      line => 9999
                        select current line for edit sessions, only a hint

=item client_edit_slink $content, $ref, $content-type, %flags

See C<client_edit_surl>

=back

=head1 SEE ALSO

L<PApp>

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://www.goof.com/pcg/marc/

=cut

1

