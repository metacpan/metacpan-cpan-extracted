use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Digest::SHA1 qw(sha1_hex);

BEGIN{ 

unless( $ENV{AWS_ACCESS_KEY_ID} && 
        $ENV{AWS_ACCESS_KEY_SECRET} && 
        $ENV{AWS_TEMPLATE_BUCKET} ){

  plan skip_all => "We need Amazon Environment information to run tests. The following variables are needed.\n AWS_TEMPLATE_BUCKET,AWS_ACCESS_KEY_SECRET, AWS_ACCESS_KEY_ID ";

}

eval 'use Template';
plan skip_all => 'Test can not continue withot Template Toolkit installed. ' if $@;
eval 'use Net::Amazon::S3';
plan skip_all => 'Test can not continue withote Net::Amazon::S3 installed. ' if $@;
use_ok('Template::Provider::Amazon::S3') 


}

sub template_setup() {
    my $ts3 = Template::Provider::Amazon::S3->new(
       cache_options => { 
              driver => 'Memcached',
           namespace => 'templates' ,
             servers => [ "127.0.0.1:11211" ]
       },
    ); #let's use the environment variables.
    my $template = Template->new( 
       LOAD_TEMPLATES => [ $ts3 ], 
       cache_options => { 
              driver => 'Memcached',
           namespace => 'templates' ,
             servers => [ "127.0.0.1:11211" ]
       },
       );
    ok( $template , 'We got a template object');
    ok( $ts3 , 'We got a Template Provider S3 object');
    return ($ts3, $template);
}

sub do_retrieval_test {

   #let's use the environment variables.
   my ($ts3, $template) = template_setup;
   my $bucket = $ts3->bucket;
   ok($bucket, "We got a bucket for $ENV{AWS_TEMPLATE_BUCKET} ");
   my $stream = $bucket->list;
   my @keys;
   until( $stream->is_done ){
     foreach my $object ( $stream->items ){
        note( 'Found object: '.$object->key );
        note( 'Does object exists: '.$object->exists );
        push @keys, [$object->key, !!$object->exists];
     }
   }

   foreach my $key_pair ( @keys ) {
      
      #my $sobj   = $bucket->object( key => $key_pair->[0] );
      my $object = $ts3->object( key => $key_pair->[0] );
      ok( defined $object , 'Get key: '.$key_pair->[0] );
      #ok( defined $sobj , 'sobj Get key: '.$key_pair->[0] );
      ok( !!$object->{template_exists} == !!$key_pair->[1] , 'Exists key: '.$key_pair->[0]);
      #ok( !!$sobj->exists == !!$key_pair->[1] , 'sobj Exists key: '.$key_pair->[0]);

   }


}

# First we need to get a template object;
sub do_basic_test {
    my ($ts3, $template) = template_setup;
    
    ok($ts3, 'We got a good provider');
    my ($content,$error,$mod_date) = $ts3->_template_content('helloworld.tt');
    note( "Values are: ".Dumper($content, $error, $mod_date));
    ok(defined $content, 'We are able to get content from S3 ' . ((defined $error) ? "error: $error" : ''));
    
    SKIP:{
      skip 'Can not check an undefined value. ', 1 unless defined $content;
      ok($content =~/Hello\s+\[%\s+name/i, 'Content is what we expect');
    }
    
}


sub process_template($$$$) {
   my ($template, $template_name, $vars, $expected) = @_;
    my $output = "";
    ok( $template->process( $template_name, $vars, \$output ), 
        "Processing the template($template_name)." );
    my $err = $template->error();
    diag(' Got template error of: '. $err ) if $err;
    SKIP:{
      skip 'Can not check an undefined value. ', 1 unless defined $output;
      note( " Output is: $output" );
      ok($output=~/$expected/i, 'Content is what we expected');
    }

    return $output;
}


sub do_template_tests {
    my ($ts3, $template) = template_setup;
    SKIP:{ 
       skip 'Can not continue without a template object', 2*4 unless $template;
       my $output = process_template $template, 'helloworld.tt', { name => 'John' }, qr/Hello\s+John/;
       my $outsha1 = sha1_hex($output);

       my $cobj = $ts3->_get_object( key => 'helloworld.tt' );
       ok( $cobj, 'The cache contains an object for template "helloworld.tt"' );
       my $cache_obj = $cobj || {}; 
       note Dumper $cache_obj;
       ok( $cache_obj->{template}, 'The template contains a value for template "helloworld.tt"');
       ok( $cache_obj->{last_modified}, 'The date contains a value for template "helloworld.tt"');
       my $cache_template = $cache_obj->{template} ? $cache_obj->{template} : '__UNDEF_SHOULD_NOT_MATCH_ANYTHING__';
       my $output1 = process_template $template, \$cache_template , { name => 'John' }, qr/Hello\s+John/;
       my $outsha11 = sha1_hex($output1);
       ok( $output1, 'The cache containted a value' );
       ok( $outsha1 eq $outsha11, "Template ($outsha1) is the same, in cache($outsha11)" );
       
    }
}

sub do_simple_wrapped_tests {
    my ($ts3, $template) = template_setup;
    SKIP:{ 
       skip 'Can not continue without a template object', 2*1 unless $template;

       process_template $template, 'wrapped_content.tt', { name => 'Foo' }, qr/This is a simple HTML wrapper/;
    
    };
}


do_retrieval_test;
do_retrieval_test;
do_basic_test;
do_template_tests;
do_simple_wrapped_tests;
done_testing;
