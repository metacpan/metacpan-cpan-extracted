use 5.10.0;
use feature 'state';
use strict;
use warnings;

package Template::Provider::Amazon::S3;
{
  $Template::Provider::Amazon::S3::VERSION = '0.009';
}

# ABSTRACT: Enable template toolkit to use Amazon's S3 service as a provier of templates.
use base 'Template::Provider';

# use version 0.77; our $VERSION = version->declare("v0.0.1");

use Net::Amazon::S3::Client;
use DateTime;
use Try::Tiny;
use List::MoreUtils qw( uniq );
use CHI 0.50;
use JSON qw(decode_json);


sub _init {
    my ( $self, $options ) = @_;
    $self->{AWS_ACCESS_KEY_ID} = $options->{key}
      || $ENV{AWS_ACCESS_KEY_ID};
    $self->{AWS_SECRET_ACCESS_KEY} =
         $options->{secret}
      || $options->{secrete}
      || $ENV{AWS_ACCESS_KEY_SECRET};
    $self->{BUCKETNAME} = $options->{bucketname}
      || $ENV{AWS_TEMPLATE_BUCKET};
    $self->{REFRESH_IN_SECONDS} =
         $options->{refresh_in_seconds}
      || $ENV{TEMPLATE_AWS_REFRESH_IN_SECONDS}
      || 86400;    # Default is a day.



    my $cache_opts = $options->{cache_options};

    if ( $ENV{AWS_S3_TEMPLATE_CACHE_OPTIONS} && !$cache_opts ) {

        try {
            $cache_opts = decode_json( $ENV{TEMPLATE_CACHE_OPTIONS} );
        }
        catch {
            $cache_opts = undef;
        };

    }
    $cache_opts ||= { driver => 'RawMemory', global => 1 };
    $self->{CACHE_OPTIONS} = $cache_opts;

    #$self->refresh_cache;
    $self->SUPER::_init($options);
}


sub client {

    my $self = shift;
    return $self->{CLIENT} if $self->{CLIENT};
    my $s3 = Net::Amazon::S3->new(
        aws_access_key_id     => $self->{AWS_ACCESS_KEY_ID},
        aws_secret_access_key => $self->{AWS_SECRET_ACCESS_KEY},
        retry                 => 1,
    );
    $self->{CLIENT} = Net::Amazon::S3::Client->new( s3 => $s3 );

}


sub bucket {
    my $self = shift;
    return $self->{BUCKET} if $self->{BUCKET};
    return unless $self->{BUCKETNAME};
    my $client = $self->client;
    return unless $self->client;
    $self->{BUCKET} = $client->bucket( name => $self->{BUCKETNAME} );
}


{
    my $last_refresh;

    sub _set_last_refresh {
        my ( $self, $time ) = @_;
        $last_refresh = $time ? $time : DateTime->now;
    }
    sub last_refresh { $last_refresh || _set_last_refresh }
}


{


use Data::Dumper;
    my $cache;
    sub cache {
        my ( $self ) = @_;
        $cache = CHI->new( %{ $self->{CACHE_OPTIONS} } ) unless $cache;
        return $cache;
    }

    sub set_cache {
       my ( $self, $key, $obj ) = @_;
       $self->cache->set( $key, $obj, $self->{REFRESH_IN_SECONDS} );
       return $self;
    }

    sub refresh_cache {

        my $self   = shift;
        my $key    = shift;
        my $bucket = $self->bucket;
        return unless $bucket;
        my $stream = $bucket->list;
        my $today = DateTime->now;
        until ( $stream->is_done ) {
            foreach my $object ( $stream->items ) {

               my $exists = !!$object->exists;
               my $ldate = $object->last_modified || $today;
               my $obj_key = $object->key;
               my $cobj = $self->cache->get( $obj_key );
               my $stash = {
                         last_modified => $ldate->epoch,
                         template_name => $key,
                       template_exists => $exists,
               };

               # This means there is no reason the update the cache. So, leave it be.
               next if ( $cobj and ( $ldate->epoch <= ($cobj->{last_modified} + 0)) ); 

               # try {
               if( $key && $exists && $key eq $obj_key ){
                  my $data = $object->get;
                  $stash->{template} = $data;
               }
               # } catch {
                    #warn "Could not get template '".$object->key."' with error $_ ";
               # };

               $self->set_cache( $obj_key, $stash );
               
            };
            $self->_set_last_refresh;
        }
        return $self->_get_object( key => $key ) if $key;
    }

}


sub _clean_up_path($) { join '/', grep { $_ !~ /\.{1,2}/ } split '/', shift; }
sub _get_paths {
    my ($self,$key)  = @_;
    my @paths = grep { defined } 
                map { /^\s*$/ ? undef : $_ } uniq
                map { _clean_up_path $_ } ( '', @{ $self->include_path } );
    return ( $key, map { join '/', $_, $key } @paths );
}

sub _get_object {
    my ( $self, %args ) = @_;
    my $key = $args{key};
    return unless $key and defined wantarray;
    my @paths = $self->_get_paths($key);
    foreach my $path_key (@paths) {
        my $obj = $self->cache->get($path_key);
        next unless $obj;
        my $template = $obj->{template};
        my $exists  = $obj->{template_exists};

        if( $exists && !$template ){
          # We need to download and store the template.
          my $s3_obj = $self->bucket->object( key => $key );
          my $s3_template = $s3_obj->get;
          $obj->{template} = $s3_template;
          $self->set_cache( $key => $obj );
        };
        return $obj;
    }
    #warn "did not find the $key ";
    return;
}

sub object {
    my ( $self, %args ) = @_;
    my $key = $args{key};
    return unless $key;
    my $obj = $self->_get_object( key => $key );
    return $obj if $obj;
    return $self->refresh_cache($key);
}

sub _template_modified {
    my ( $self, $template ) = @_;
    $template =~ s#^\./##;
    my $object;
    my $ldate;
    try {
        $object = $self->object( key => $template );
        $ldate = $object->{last_modified};
    }
    catch {
        #warn "did not find the $template error was thrown $_";
        return undef;
    };
}

sub _template_content {
    my ( $self, $template ) = @_;
    $template =~ s#^\./##;
    return
      wantarray ? ( undef, 'No path specified to fetch content from' ) : undef
      unless $template;
    return
      wantarray ? ( undef, 'No Bucket specified to fetch content from' ) : undef
      unless $self->bucket;
    my $object;
    try {
        my $template_obj = $self->object( key => $template );
        my ( $data, $mod_date ); 
        if( $template_obj  ){
           $data = $template_obj->{template};
           $mod_date = $template_obj->{last_modified};
        } else {
           return wantarray ? ( undef, 'File not found ' ) : undef;
        }
        return wantarray ? ( $data, undef, $mod_date ) : $data;
    }
    catch {
        $self->cache->remove($template);
        #$self->template_cache->remove($template);
        return wantarray ? ( undef, 'AWS error: ' . $_ ) : undef;
    };
}


1;

__END__
=pod

=head1 NAME

Template::Provider::Amazon::S3 - Enable template toolkit to use Amazon's S3 service as a provier of templates.

=head1 VERSION

version 0.009

=head1 SYNOPSIS

   use Template;
   use Template::Provider::Amazon::S3;

   # Specify the provider in the config for Template::Toolkit. 
   # Note since the AWS ACCESS KEY, SECRET, and bucket name 
   # is not provided here, it will get it from the following 
   # Envrionmental variables:
   #  AWS_ACCESS_KEY_ID
   #  AWS_SECRET_ACCESS_KEY
   #  AWS_TEMPLATE_BUCKET
   my $tt_config = {
       LOAD_TEMPLATES => [
         Template::Provider::Amazon::S3->new( INCLUDE_PATH => [ 'dir1', 'dir2' ] )
       ]
   };

   my $tt = Template->new($tt_config);
   $tt->process('file_on_s3',$vars) || die $tt->error;

=head1 METHODS

=head2 client

  This method will return the S3 client.

=head2 bucket

   This method will return the bucket that was configure in the begining.

=head2 last_refresh

  This method will return the DateTime object of the last
  time the internal cache was refreshed.

=head2 refresh_cache

  Call this method to refresh the cache.

=head2 object

   returns the object for a given key. 
   This method take a key parameter.

     $obj = $self->object( key => 'some_path' );

=head1 INHERITED METHODS

  These methods are inherited from Template::Provider and function in the same way.

=over 2

=item fetch()

=item store()

=item load()

=item include_path()

=item paths()

=item DESTROY()

=back

=head1 CLASS Methods

  $obj = $class->new( %parameters )

  constructs a new instance.

  Accepts all the arguments as the base class L<Template::Provider>, with the following additions:

=over 4

=item B<key>

  This is the Amazon Access key, if this is not provided we will try
  and load this from the AWS_ACCESS_KEY_ID environment variable.

=item B<secret>

  This is the Amazon Secret Key, if this is not provided we will try
  and load this from the AWS_ACCESS_KEY_SECRET environment variable.

=item B<bucketname>

  This is the bucket that will contain all the templates. If this it
  not provided we will try and get it from the AWS_TEMPLATE_BUCKET 
  envrionement variable. 

=item B<INCLUDE_PATH>

  This should be an array ref to directories that will be searched for the
  template. This method is really naive, and just prepends each entry to 
  the template name. 

=item B<refresh_in_seconds>

   This is the number of seconds that the cache will expire. The default for this
   is 86400 seconds, which is 1 day. This value can also be set via the environment
   variable TEMPLATE_AWS_REFRESH_IN_SECONDS.

=item B<cache_options>

   This is the options to provide to the L<CHI> cache module. This can also be set
   by the environment variable TEMPLATE_CACHE_OPTIONS. If using the environment 
   variable, the values need to be L<JSON>  encoded. Otherwise the value will be 
   an in memory store. The option send is the following:

     
     {
         driver => 'RawMemory', 
         global => 1 
     }

=back

=head2 Note

  Note do not use the RELATIVE or the ABSOLUTE parameters, I don't know 
  what will happen if they are used. 

=head1 SEE ALSO

=over 4 

=item L<Net::Amazon::S3::Client>

=item L<Net::Amazon::S3::Client::Bucket>

=item L<Net::Amazon::S3::Client::Object>

=item L<CHI>

=back

=head1 AUTHOR

Gautam Dey <gdey@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Gautam Dey <gdey@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

