use Test::More;
no warnings 'void'; # Too late to run INIT block ...

eval "use Test::Pod::Coverage tests => 1";

plan skip_all => "Test::Pod::Coverage required" if $@;

{
	local $SIG{__WARN__} = sub {
		# adapted from Class-Trait-0.07
		return if $_[0] =~ /^Too late to run INIT block/;
		goto &CORE::warn;
	};

pod_coverage_ok("Socket::MsgHdr",
                { also_private => [
                    qr/^(?:un)?pack_cmsghdr$/,
                    qr/^control$/,
                ] },
                "Socket::MsgHdr OO and default EXPORTs are covered");

}
