package Template::Magic::Slicer ;
$VERSION = 1.15 ;
use 5.006_001 ;
use strict ;
 
# This file uses the "Perlish" coding style
# please read http://perl.4pro.net/perlish_coding_style.html

; use Carp
; $Carp::Internal{+__PACKAGE__}++
; use warnings::register
; our $no_template_magic_zone = 1 # prevents passing the zone object to properties
; use Template::Magic::Pager
; push our @ISA, 'Template::Magic::Pager'


; BEGIN
   { warn qq("Template::Magic::Slicer" is a deprecated module. )
        . qq(You should use "Template::Magic::Pager" instead\n)
          if warnings::enabled
   }

    
; 1

__END__

=pod

=head1 NAME

Template::Magic::Slicer - Deprecated module (use Template::Magic::Pager)

=head1 DESCRIPTION

Deprecated module maintained for backward compatibility. Use Template::Magic instead.

=head1 AUTHOR and COPYRIGHT

© 2004 by Domizio Demichelis (L<http://perl.4pro.net>)

All Rights Reserved. This module is free software. It may be used, redistributed and/or modified under the same terms as perl itself.

=cut
