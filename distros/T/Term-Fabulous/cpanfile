requires 'perl', '5.032001';

requires 'Clay::UI', '0.07';    # focus_after and entry hooks, text bounding boxes, cut-off text, content boxes, tree navigation, owner-bound listeners; ships Clay::XS
requires 'Clay::XS', '0.07';    # stringOffset in text render commands
requires 'Encode';
requires 'Exporter';
requires 'Feature::Compat::Try';
requires 'I18N::Langinfo';
requires 'IO::Async';
requires 'List::Util', '1.33';    # any, all (1.33), pairmap (1.29)
requires 'MIME::Base64';
requires 'Object::Pad', '0.825';
requires 'Object::PadX::Enum';
requires 'POSIX';
requires 'Scalar::Util';
requires 'Socket';
requires 'Text::KDL::XS', '0.002';    # parse_kdl reads strings as characters
requires 'Time::HiRes';
requires 'Time::Local', '1.30';    # timelocal_posix
requires 'Unicode::GCString';
requires 'XSLoader';

recommends 'Imager';                # Term::Fabulous::Widget::Image; shows a notice without it
recommends 'Imager::File::SIXEL';    # Term::Fabulous::Widget::Sixel; shows a notice without it

on test => sub {
	requires 'Test2::V0';
};

# The maintainer tools in tools/ (make docs, make docs-check, tools/tidy)
# and perlcritic.
on develop => sub {
	requires 'IO::Pty';
	requires 'JSON::PP';
	requires 'Perl::Critic';
	requires 'Perl::Tidy', '20250214';
	requires 'Pod::Markdown';
	requires 'Markdent';    # the Markdown reader of Term::Fabulous::Cookbook::Documents, for its screenshots
	recommends 'Imager';                 # PNG output of tools/screenshot, the example pictures of tools/
	recommends 'Imager::File::SIXEL';    # the sixel pictures in the screenshots of tools/screenshot
};
