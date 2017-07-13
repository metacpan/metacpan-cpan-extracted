use strict;
use warnings;

use Test::More;
use PDL::IO::Image;

my @l = PDL::IO::Image->format_list;
ok(scalar(@l) > 10, "format_list");

like(PDL::IO::Image->free_image_version, qr/^\d+\.\d+\.\d+/, "free_image_version");
ok  (PDL::IO::Image->format_can_read('png'), "format_can_read");
ok  (PDL::IO::Image->format_can_write('png'), "format_can_write");
ok  (PDL::IO::Image->format_can_export_type('png', 'RGBA16'), "format_can_export_type");
ok  (PDL::IO::Image->format_can_export_bpp('png', '32'), "format_can_export_bpp");
is  (PDL::IO::Image->format_extension_list('png'),  "png", "format_extension_list");
is  (PDL::IO::Image->format_mime_type('png'), "image/png", "format_mime_type");
is  (PDL::IO::Image->format_description('png'), "Portable Network Graphics", "format_description");
is  (PDL::IO::Image->format_from_mime('image/png'), "PNG", "format_from_mime");
is  (PDL::IO::Image->format_from_file('t/bpp-32/special/png_with_extension.png'), "PNG", "format_from_file/1");
is  (PDL::IO::Image->format_from_file('t/bpp-32/special/png_without_extension'), "PNG", "format_from_file/2");

done_testing();