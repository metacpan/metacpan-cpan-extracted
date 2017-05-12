use Image::Magick;

$im=Image::Magick->new();
$im->Read('../../MasterImage_70x46.ppm');
$im->GaussianBlur('0.0x1.5');
$im->Set(depth=>8);
$im->Write('GaussianBlur.miff');

