use melody_compiler::compiler;
use std::ffi::CStr;
use std::ffi::CString;

#[no_mangle]
pub extern "C" fn melody_compiler(input: *const i8) -> *const i8 {
    let input = unsafe { CStr::from_ptr(input) };
    let output = compiler(input.to_str().unwrap()).unwrap();
    CString::new(output).unwrap().into_raw()
}
