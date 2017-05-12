#!perl
use warnings;
use strict;

use Test::More tests => 49;

BEGIN{ use_ok('Ruby', ':DEFAULT', 'String') }

use IO::Handle;
use SelectSaver;

{
	my $s = '';
	open my($sfh), ">:scalar", \$s;
	my $ss = SelectSaver->new($sfh);

	$sfh->autoflush;

	puts 'foo';

	is $s, "foo\n", "puts() to the default filehandle";

	puts 'bar';

	is $s, "foo\nbar\n";

	close $sfh;
	$s = '';
	open $sfh, ">:scalar", \$s;

	p "foo";

	is $s, qq{"foo"\n}, "p() to the default filehandle";

	p String("bar\n");

	is $s, qq{"foo"\n"bar\\n"\n};

}

no warnings 'io';

rb_eval <<'EOT', __PACKAGE__, __FILE__, 0;


ok defined?(Perl::STDIN),  "defined? STDIN";
ok defined?(Perl::STDOUT), "defined? STDOUT";
ok defined?(Perl::STDERR), "defined? STDERR";

is STDIN.fileno,  Perl::STDIN.fileno,  "stdin  fileno";
is STDOUT.fileno, Perl::STDOUT.fileno, "stdout fileno";
is STDERR.fileno, Perl::STDERR.fileno, "stderr fileno";

io = Perl.open('foo', 'w+', 0666);


ok(io, "Perl.open");
ok(!io.closed?, "closed?");

ok(io.path, 'foo', "Perl::IO path");

io.binmode(:raw);

begin
	io.binmode('UnknownLayer');
rescue
	is $!.class, ArgumentError, "binmode UnknownLayer";
end

is io.pos,  0, "pos";
is io.tell, 0, "tell";

io.putc(?f);
io.putc(?o);
io.putc(?o);
io.putc("\n");

io.puts("bar");

is io.pos, 8, "pos";

ok io.flush, "flush";

ok io.inspect =~ /RDWR/, "inspect";

io.rewind;

is(io.gets, "foo\n", "putc/puts/rewind/gets");
is(io.gets, "bar\n");

io.seek(0, IO::SEEK_SET);

is(io.pos, 0, "seek/pos");

io.lineno = 0;

io.each { |line|
	ok line, "each";
}
is io.lineno, 2, "lineno";


io.pos = 2;

is(io.pos, 2, "pos=");

io.rewind;

is(io.lineno, 0, "rewind() reset lineno");

is(io.read(), "foo\nbar\n", "read all");

io.rewind;

is(io.readline, "foo\n", "readline");
is(io.read(),   "bar\n", "read remain");

ok io.eof?, "eof?";

ok(!io.closed?, "closed?");

rubyio = io.to_io;
is rubyio.class, IO, "to_io";
rubyio.close;

io.close;

ok(io.closed?, "close/closed?");

begin
	io.getc;
rescue IOError
	pass "evil fh";
end


Perl.open("foo", "<:crlf") do |io|
	a = io.readlines;

	is a.length, 2, "open BLOCK/readlines";
	is a[0], "foo\n", "readlines[0]";
	is a[1], "bar\n", "readlines[1]";

	ok a[0].tainted?, "tainted?";

	io.rewind;

	is io.read(2), "fo", "read(size)";
	is io.getc, ?o, "getc";

	io.ungetc(?o);

	is io.getc, ?o, "ungetc";

	begin
		while(line = io.readline)
			;
		end
	rescue
		is $!.class, EOFError, "End of file reached";
	end
end

ok io.closed?, "open BLOCK; autoclose";


io = Perl.open("foo", "r+");
io.truncate(0);

io.seek(0, IO::SEEK_END);
is io.pos, 0, "truncate";

ok io.read.nil?, "read empty file";

io.close;


begin
	Perl.open("foobar", "<");
rescue
	is $!.class, Errno::ENOENT, "no such file or directory";
end

GC.start;

File.unlink("foo");

EOT

END{
	pass "test end";
}