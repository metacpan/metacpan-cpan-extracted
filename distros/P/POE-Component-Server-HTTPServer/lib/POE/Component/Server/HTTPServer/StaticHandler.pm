package POE::Component::Server::HTTPServer::StaticHandler;
use strict;
use HTTP::Status;
use MIME::Types;
use POE::Component::Server::HTTPServer::Handler;
use base 'POE::Component::Server::HTTPServer::Handler';

# _init( $root [, index_file => $index_file] [, auto_index => $auto_index ] )
#    Files will be served relative to $root
#    If a request is made for a directory, then:
#      If $index_file is defined and found, it will be returned.
#      Else, if $auto_index is defined, a directory index will be generated.
#    Otherwise, this handler will pass on the request.
sub _init {
  my $self = shift;
  my $root = shift;
  my %args = @_;
  $self->{root} = $root;
  $self->{mimetypes} = MIME::Types->new(); # ugh
  if ( exists($args{index_file}) ) {
    $self->{index_file} = $args{index_file};
  } else {
    $self->{index_file} = 'index.html';
  }
  if ( exists($args{auto_index}) ) {
    $self->{auto_index} = $args{auto_index};
  } else {
    $self->{auto_index} = 0;
  }
}

sub handle {
  my $self = shift;
  my $context = shift;
  #print "Handling static request (", __PACKAGE__, ")\n";
  my $cpath = $context->{contextpath};
  #print "Context path=$cpath\n";
  # scrub path (badly): XXX fix this with file::spec or the like
  if ( $cpath =~ m[(^|/)\.\.(/|$)] ) {
    warn "Will not serve dangerous path '$cpath'\n"; # should keep silent here
    return H_CONT;
  }
  my $filepath = "$self->{root}/$cpath";
  #print "static root: $filepath\n";
  if ( -d $filepath ) {
    return $self->handle_directory($filepath, $context);
  } elsif ( -f $filepath ) {
    return $self->handle_plainfile($filepath, $context);
  } else {
    #print "Request for non-existant file: $filepath\n";
    return H_CONT;
  }
}

sub handle_plainfile {
  my $self = shift;
  my $filepath = shift;
  my $context = shift;
  if ( open(my $in, $filepath) ) {
    binmode($in);
    local $/ = undef;
    $context->{response}->code( RC_OK );
    my $type = $self->{mimetypes}->mimeTypeOf( $filepath );
    $type='text/plain' unless defined($type);
    $context->{response}->content_type( $type );
    $context->{response}->content(<$in>);
    return H_FINAL;
  } else {
    #print "Failed to open $filepath ($!)\n";
    $context->{error_message} = $!; # XXX security: returned with 404 response
    return H_CONT;
  }
}

sub handle_directory {
  my $self = shift;
  my $filepath = shift;
  my $context = shift;
  #print "directory( $filepath )\n";
  if ( $self->{index_file} ) {
    my $index_file = "$filepath/$self->{index_file}";
    if ( -e $index_file ) {
      return $self->handle_plainfile( $index_file, $context );
    }
  }
  if ( $self->{auto_index} ) {
    # nasty hack: should probably just not include this option
    if ( opendir(my $dir, $filepath) ) {
      my $page = qq{<HTML><HEAD><TITLE>Directory Index</TITLE></HEAD>\n};
      $page .= qq{<BODY bgcolor="#aaccaa">\n};
      $page .= qq{<P>Directory Index</P><HR />\n};
      $page .= qq{<UL>\n};
      my $base = $context->{request}->uri;
      while(my $fn = readdir($dir)) {
	next if $fn=~/^\./;
	$page .= qq{<LI><A HREF="$base/$fn">$fn</A></LI>\n};
      }
      $page .= qq{</UL>\n};
      $page .= qq{</BODY></HTML>\n};
      $context->{response}->code( RC_OK );
      $context->{response}->content( $page );
      return H_FINAL;
    } else {
      # XXX should this class of problem be a 500?
      #print "Failed to opendir ($!)\n";
      $context->{error_message} = $!; # XXX security: returned with 404 resp
      return H_CONT;
    }
  }
  return H_CONT;
}

1;
__END__

=pod

=head1 NAME

POE::Component::Server::HTTPServer::StaticHandler - serve static files

=head1 SYNOPSIS

  use POE::Component::Server::HTTPServer;
  my $server = POE::Component::Server::HTTPServer->new();
  $server->handlers([ '/static' => new_handler( 'StaticHandler',
						$static_root ),
		      '/static2' => new_handler( 'StaticHandler',
				                 $static_root,
                                                 auto_index => 1,
                                                ),
		    ]);

=head1 DESCRIPTION

StaticHandler provides a request handler which serves static
filesystem resources relative to a given root.  It may also be
subclassed to handle interpreted requests based on filesystem
resources such as parsed or templated pages.

StaticHandler expects to be created with at least one argument.  The
first argument should be the location of the document root.  Requests
relative to the prefix associated with this handler will be resolved
to file names relative to this directory.  If found, the contents of
the file will be returned as the response.

StaticHandler may also be given the following arguments when created:

=over 4

=item B<auto_index>

If set to true, a (crude) directory index response will be generated
for requests which map to directories.  The default is false.

=item B<index_file>

If defined, requests which map to directories will instead be resolved
to this file (in the relevant directory), if such an index file
exists.  This setting takes precedence over C<auto_index>.  The
default is C<index.html>.

=back

=head2 Subclassing StaticHandler

When handling requests, StaticHandler invokes two methods which may be
overridden to modify the default behavior.  One of the following is
invoked when StaticHandler resolves a request to a given file or
directory:

=over 4

=item B<$self-E<gt>handle_plainfile($filepath, $context)>

Called when the request maps to a plain file.  C<$filepath> is the
full path to the file, and C<$context> is the HTTPServer context.

=item B<$self-E<gt>handle_directory($filepath, $context)>

Called when the request maps to a directory.  C<$filepath> is the full
path to the file, and C<$context> is the HTTPServer context.

=back

=head1 SEE ALSO

L<POE::Component::Server::HTTPServer>, 
L<POE::Component::Server::HTTPServer::TemplateHandler>

=head1 AUTHOR

Greg Fast <gdf@speakeasy.net>

=head1 COPYRIGHT

Copyright 2003 Greg Fast.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
