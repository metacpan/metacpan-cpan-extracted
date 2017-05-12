package String::Prettify;
use Exporter;
use vars qw($VERSION @EXPORT @ISA);
@ISA=qw/Exporter/;
@EXPORT = qw(prettify prettify_filename);
use strict;
use Carp;
$VERSION = sprintf "%d.%02d", q$Revision: 1.4 $ =~ /(\d+)/g;

sub prettify {
   my $string = shift;
   $string or croak("missing argument");

   _depathify(\$string);
   _ampersand(\$string);
   _spacing(\$string);


   _cap(\$string);

   return $string;
}

sub prettify_filename {
   my $string = shift;
   $string or croak("missing argument");
   
   $string=~s/^(.+\/+)//;
   my $loc = $1;

   my $ext = _ext(\$string);
   _spacing(\$string);

   $string=~s/ /_/g;
   #$string = lc $string;

   no warnings;
   return "$loc$string$ext";


}


# privates.... 


sub _cap {
   my $ref = shift;
   #my $string = lc($$_ref);
   
   $$ref=~s/\b([a-z])/uc($1)/ge;
   return;
}
   
sub _ext {
   my $_ref = shift;
   if( $$_ref=~s/(\.\w{1,8})$// ){
      return $1;
   }
   return;
}
   
   
sub _depathify {
   my $r = shift;

   $$r=~s/^.+\/+//;
   
   _ext($r);
   
   return;
}
   
sub _spacing {
   my $ref = shift;

   $$ref=~s/[_\W]/ /g;
   
   $$ref=~s/([0-9])([a-zA-Z])/$1 $2/g;
   $$ref=~s/([a-zA-Z])([0-9])/$1 $2/g;
   
   
   $$ref=~s/([a-z])([A-Z])/$1 $2/g;
   $$ref=~s/ {2,}/ /g;
   $$ref=~s/^\s+|\s+$//g;
   return;
   
}

sub _ampersand {
   my $ref = shift;

   $$ref=~s/(\d)&(\d)/$1 $2/g;

   $$ref=~s/^&|&$/_and_/g;

   my $r = qr/[a-z ]{2,}|[[^a-z]\b]/i;

   $$ref=~s/($r)&($r)/$1_and_$2/g;

   $$ref=~s/&//g;
   
   #$$ref=~s/(\W)&(\W)/$1_and_$2/g;

   #$$ref=~s/(\b[a-z])&([a-z])\b/$1$2/ig; # H&R HR


   #$$ref=~s/([^ a-z])&([^ a-z])/$1_$2/ig;

   #$$ref=~s/\b&\b/_and_/g;



}



1;

__END__

=pod

=head1 NAME

String::Prettify - subs to cleanup a filename and or garble for human eyes

=head1 SYNOPSIS

   use String::Prettify

   print prettify('Johny & Mary Jacobs #3rd');

   my $ugly   = '/home/This Here235#$%@%/!!great-superfuper skatingVideo132.mov';
   my $pretty = prettify_filename($ugly);
   rename( $ugly, $pretty );


=head1 DESCRTIPTION

I was tired of turning things like '/var/www/dms/doc/Clients_ALTERNATe/Universal Title LLC/Vendors/2005/Invoices/JOE RAGANS COFFEE/092705-JOE RAGANS COFFEE-031003.pdf' into '092705 JOE RAGANS COFFEE 031003'

=head2 When would you want to use this?

Imagine you are using cgi to show files. The client selects a file. You want to title the output html page after the file. And maybe, just maybe-
the file selected is a directory.
Well, then a location called '/home/username/public_html/art/_grand_juryFinals' could be turned into
'Grand Jury Finals' on the fly.

   my $title = prettify('/home/username/public_html/art/_grand_juryFinals');
   # 'Grand Jury Finals'

=head1 SUBS

Are exported on use.

=head2 prettify()

Argument is string
Returns prettified.


=head2 prettify_filename()

Argument is path argument
Returns prettified.
The extension and location is unchanged (if present).
If you provide a path with slashes etx, we don't change any of that. We jsut return a cleaner filename.
This is useful if you have a directory with stupid filenames like:
   !!great-superfuper skatingVideo132.mov
And you want to clean them up.

   my $ugly   = '/home/This Here235#$%@%/!!great-superfuper skatingVideo132.mov';
   my $pretty = prettify_filename($ugly);
   rename( $ugly, $pretty );

The location remains the same.

=head1 REQUIREMENTS

None.

=head1 CAVEATS

In development. If you have suggestions, please notify the AUTHOR.

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut


