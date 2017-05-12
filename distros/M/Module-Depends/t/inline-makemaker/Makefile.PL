use Inline::MakeMaker;

WriteInlineMakefile(
  'NAME'            => 'FFmpeg',
  'VERSION_FROM'    => 'FFmpeg.pm', # finds $VERSION
  'PREREQ_PM'       => {
      Inline::C     => 0.44,
      Time::Piece   => 1.08,
      #                         Image::PBMlib => 1.06,
      #                         Image::Magick => 5.56,
  },
 );
