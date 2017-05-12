#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Template::TT - Use Template::Toolkit with Rex

=head1 DESCRIPTION

This module enables the use of Template::Toolkit for Rex Templates.

=head1 USAGE

Just include the file into your I<Rexfile>.

 # Rexfile
 use Rex::Template::TT;
    
 task prepare => sub {
    
    file "/a/file/on/the/remote/machine.conf",
       content => template("path/to/your/template.tt", 
                              var1  => $var1,
                              arr1  => \@arr1,
                              hash1 => \%hash1,
                          );
                       
 };

=cut
   
package Rex::Template::TT;

use strict;
use warnings;

our $VERSION = "0.33.1";

use Template;

use Rex -base;

sub import {

   set template_function => sub {
      my ($content, $vars) = @_;
      my $t = Template->new;
      my $out;
      $t->process(\$content, $vars, \$out);
      return $out;
   };

}

1;
