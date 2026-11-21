requires 'perl', '5.040';

requires 'B';
requires 'Carp';
requires 'Compress::Raw::Zlib';
requires 'Cwd';
requires 'Digest::SHA';
requires 'Encode';
requires 'Errno';
requires 'Exporter';
requires 'Fcntl';
requires 'File::Spec';
requires 'HTTP::Tiny', '0.083';
requires 'Hash::Ordered';
requires 'IO::Handle';
requires 'IO::Select';
requires 'IO::Socket::SSL', '1.968';
requires 'JSON::MaybeXS', '1.004000';
requires 'Moo', '2.000000';
requires 'Moo::Role';
requires 'Net::SSLeay', '1.49';
requires 'POSIX';
requires 'Path::Tiny', '0.119';
requires 'Scalar::Util';
requires 'Sys::Hostname';
requires 'Text::Nunjucks', '0.001';
requires 'Time::HiRes';
requires 'Unicode::Normalize';
requires 'namespace::clean';

# Skilletor::Process's detached spawn on Windows (Strawberry Perl ships it).
if ( $^O eq 'MSWin32' ) {
  requires 'Win32::Process';
}

on test => sub {
  requires 'FindBin';
  requires 'IO::Compress::Gzip';
  requires 'IO::Socket::INET';
  requires 'IPC::Open2';
  requires 'Test::More', '0.96';
  requires 'version', '0.77';
};
