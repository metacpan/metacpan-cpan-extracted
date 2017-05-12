package P50Tools;

# ABSTRACT: This tool is just to work with pen-test, but to study to. 

use common::sense;
use P50Tools::SQLiScan;
use P50Tools::RFIScan;
use P50Tools::RandoDoors;
use P50Tools::LFIScan;
use P50Tools::AdminFinder;

{
    no strict "vars";
    $VERSION = '0.62';
}

if ($^O ne m/MSW/gi) {require P50Tools::Packs}
else { print "You'll cannot use P50Tools::Packs\n"}


1;

__END__

=head1 NAME

P50Tools - This tool is just to work with pen-test, but to study to.

=head1 VERSION

This is the documentation of C<P50Tools> version 0.62

=head1 SYNOPSIS

########Search Adm Page########
use P50Tools;

my $p = P50Tools::AdminFinder->new();
$p->target('my.target.lan');
# $p->string_list('MyStringList.txt'); this method can be used optionally if you had other list of strings
$p->scan;


########Search Local File Inclusion fail########
use P50Tools;

my $p = P50Tools::LFIScan->new();
$p->target('my.target.lan');
# $p->string_list('MyStringList.txt'); this method can be used optionally if you had other list of strings
$p->scan;

########Search Remote File Inclusion fail########
use P50Tools;

my $p = P50Tools::RFIScan->new();
$p->target('my.target.lan');
# $p->string_list('MyStringList.txt'); this method can be used optionally if you had other list of strings
# $p->php_shell('My.SiteWith.file/php_name.txt'); this method can be used optionally if you had other file with php shell code
# $p->response('response'); this method needs to be configured according to the php shell used
$p->scan;

########Search SQL injection fail########
use P50Tools;

my $p = P50Tools::SQLiScan->new();
$p->target_list('my_list_with_target.txt');
$p->output('my_results.txt');
$p->scan;

########Search open doors in a target########
use P50Tools;

my $p = P50Tools::RandonDoors->new();
$p->target('my.target.lan');
$p->ini(78); 
$p->end(82);
# To use defaults doors don't declare 'ini' and 'end' methods, will be search all doors
# $p->timeout(20); this method can be used optionally
$p->scan;

########Stress test########
use P50Tools;

my $p = P50Tools::Packs->new();
$p->target('my.target.lan');
$p->door(80);
$p->send;

=head1 DESCRIPTION

This package is a tool made to study and initial pen-test.
I don't matter if you use to other things.
You can use this package to exploit fail.

=head1 METHODS

=head1 P50Tools::AdminFinder

This tool can find admin page. Can be use with default list or you
can configurate to use an new list.

=item target

Here you defined target to search admin page.

=item string_list

Here you can defined which list of string you will use, default or new list.

=item scan

This is a essential declaration, because here will start search.

=item output

Here you set the output file name.

=head1 P50Tools::LFIScan

This tool can find a LFI vulnerability in a site.

=item target

Here you defined target to search Local File Inclusion fail.

=item string_list

Here you can defined which list of string you will use, default or new list.

=item scan

This is a essential declaration, because here will start search.

=item output

Here you set the output file name.

=head1 P50Tools::RFIScan

This tool can find a RFI vulnerability in a site.

=item target

Here you defined target to search Remote File Inclusion fail.

=item string_list

Here you can defined which list of string you will use, default or new list.

=item php_shell

Here you can defined the page with php shell code to incusion.

=item response

If you defined a non default php_shell method you need modified this value.
Here you defined the response wait to php_shell.

=item scan

This is a essential declaration, because here will start search.

=item output

Here you set the output file name.

=head1 P50Tools::SQLiScan

This tool can find a SQLi vulnerability in a site.

=item target_list

Is usual serarch SQLi fail in a list of pages extracted of a server. 
Here you set the file with the list.

=item output

Here you set the output file name.

=item scan

This is a essential declaration, because here will start search.

=head1 P50Tools::RandonDoors

This tool can be use to find a open doors in a target.

=item target

Here you defined target to search doors.

=item ini

Here you can defined initial door to start scan or use default "1".

=item end

Here you can defined initial door to end scan or use default "65000".

=item timeout

Here you can defined the time of connection, default is "20".

=item scan

This is a essential declaration, because here will start search.

=head1 P50Tools::Packs

This package do a stress test in a target type Syn Flood. This tools require the
L<Net::RawIP> module. The Net::RawIP is an interface to libpcap, and are 
implemented on Linux and BSD only.

This tool don't will be work in other system.

But you can modified, you can try.

=item target

Here you defined target to send packs.

=item door

Here you can defined the door that will be use in this attack.

=item send

This is a essential declaration, because here will start send packs.

head1 AUTHORS

Aureliano C Proença Guedes E<lt>guedes_1000@hotmail.comE<gt>

=back

=head1 LICENSE

All rights reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

