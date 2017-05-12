package Tangram::RefImage;
use Tangram qw(:compat_quiet);
use base qw(Tangram::Ref);
$Tangram::Schema::TYPES{ref_image} = Tangram::RefImage->new();

