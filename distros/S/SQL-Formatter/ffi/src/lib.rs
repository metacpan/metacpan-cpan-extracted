use std::ffi::CString;
use std::ffi::CStr;
use sqlformat::format;
use std::os::raw::c_char;

#[no_mangle]
pub fn sf_format(query: *const c_char, indent: u8, uppercase: bool, between: u8) -> *mut c_char {
    let query = unsafe { CStr::from_ptr(query) };
    let options = sqlformat::FormatOptions {
        indent: sqlformat::Indent::Spaces(indent),
        uppercase: uppercase,
        lines_between_queries: between,
    };
    let query = format(query.to_str().unwrap(), &sqlformat::QueryParams::default(), options);

    CString::new(query).unwrap().into_raw()
}

#[allow(non_snake_case)]
#[no_mangle]
pub fn sf__free(s: *mut c_char) {
    if s.is_null() {
    } else {
        unsafe { drop(CString::from_raw(s)) };
    }
}
