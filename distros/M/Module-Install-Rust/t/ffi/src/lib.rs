#[no_mangle]
pub extern "C" fn double(v: u32) -> u32 {
    v * 2
}

extern "C" {
    fn perl_alloc() -> *mut u8;
}

// This function is supposed to test that symbols provided by the parent Perl process are not
// causing errors during link time. Actually calling this from running perl interpreter may not be
// safe.
#[no_mangle]
pub extern "C" fn test_link_ok() {
    unsafe { perl_alloc() };
}
