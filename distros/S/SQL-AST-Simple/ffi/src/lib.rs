//! C ABI shim around the `sqlparser` crate for SQL::AST::Simple.
//!
//! Two operations are exported: parse SQL text into the serde JSON form of
//! the `sqlparser` AST, and turn that JSON back into SQL text.  Every string
//! returned to the caller is a NUL terminated, heap allocated C string that
//! must be released with `sql_ast_simple_free`.

use sqlparser::ast::{Expr, Statement};
use sqlparser::dialect::{dialect_from_str, Dialect};
use sqlparser::parser::Parser;
use sqlparser::tokenizer::Token;
use std::ffi::{c_char, CStr, CString};
use std::ptr;

/// Borrow a C string as `&str`, rejecting NULL and invalid UTF-8.
unsafe fn borrow<'a>(p: *const c_char) -> Result<&'a str, String> {
    if p.is_null() {
        return Err("NULL string argument".to_string());
    }
    CStr::from_ptr(p)
        .to_str()
        .map_err(|e| format!("argument is not valid UTF-8: {e}"))
}

/// Convert a result into the C return convention: on success return the
/// string and clear `*err_out`; on failure return NULL and store the
/// message in `*err_out`.
fn finish(err_out: *mut *mut c_char, result: Result<String, String>) -> *mut c_char {
    let result = result.and_then(|s| {
        CString::new(s).map_err(|_| "result contains an embedded NUL byte".to_string())
    });
    match result {
        Ok(cstr) => {
            if !err_out.is_null() {
                unsafe { *err_out = ptr::null_mut() };
            }
            cstr.into_raw()
        }
        Err(msg) => {
            if !err_out.is_null() {
                let msg = CString::new(msg.replace('\0', "")).expect("NUL bytes were stripped");
                unsafe { *err_out = msg.into_raw() };
            }
            ptr::null_mut()
        }
    }
}

/// Look up a dialect by name.
fn dialect(name: *const c_char) -> Result<Box<dyn Dialect>, String> {
    let name = unsafe { borrow(name) }?;
    dialect_from_str(name).ok_or_else(|| format!("unknown dialect: {name}"))
}

/// Parse `sql` using the named dialect and return the AST as a JSON array
/// of statements.
#[no_mangle]
pub extern "C" fn sql_ast_simple_parse(
    dialect: *const c_char,
    sql: *const c_char,
    err_out: *mut *mut c_char,
) -> *mut c_char {
    let result = (|| {
        let dialect = self::dialect(dialect)?;
        let sql = unsafe { borrow(sql) }?;
        let ast = Parser::parse_sql(&*dialect, sql).map_err(|e| e.to_string())?;
        serde_json::to_string(&ast).map_err(|e| e.to_string())
    })();
    finish(err_out, result)
}

/// Parse `sql` as a single expression, such as the body of a `WHERE`
/// clause, and return it as JSON.  Anything left over after the expression
/// is an error.
#[no_mangle]
pub extern "C" fn sql_ast_simple_parse_expr(
    dialect: *const c_char,
    sql: *const c_char,
    err_out: *mut *mut c_char,
) -> *mut c_char {
    let result = (|| {
        let dialect = self::dialect(dialect)?;
        let sql = unsafe { borrow(sql) }?;
        let mut parser = Parser::new(&*dialect)
            .try_with_sql(sql)
            .map_err(|e| e.to_string())?;
        let expr = parser.parse_expr().map_err(|e| e.to_string())?;
        parser
            .expect_token(&Token::EOF)
            .map_err(|e| e.to_string())?;
        serde_json::to_string(&expr).map_err(|e| e.to_string())
    })();
    finish(err_out, result)
}

/// Turn a JSON array of statements (as produced by `sql_ast_simple_parse`,
/// possibly modified) back into SQL text.  Statements are joined with
/// `"; "`, or `";\n"` when `pretty` is set.
#[no_mangle]
pub extern "C" fn sql_ast_simple_unparse(
    json: *const c_char,
    pretty: bool,
    err_out: *mut *mut c_char,
) -> *mut c_char {
    let result = (|| {
        let json = unsafe { borrow(json) }?;
        let ast: Vec<Statement> = serde_json::from_str(json).map_err(|e| e.to_string())?;
        let parts: Vec<String> = ast
            .iter()
            .map(|s| if pretty { format!("{s:#}") } else { s.to_string() })
            .collect();
        Ok(parts.join(if pretty { ";\n" } else { "; " }))
    })();
    finish(err_out, result)
}

/// Turn a JSON expression (as produced by `sql_ast_simple_parse_expr`,
/// possibly modified) back into SQL text.
#[no_mangle]
pub extern "C" fn sql_ast_simple_unparse_expr(
    json: *const c_char,
    err_out: *mut *mut c_char,
) -> *mut c_char {
    let result = (|| {
        let json = unsafe { borrow(json) }?;
        let expr: Expr = serde_json::from_str(json).map_err(|e| e.to_string())?;
        Ok(expr.to_string())
    })();
    finish(err_out, result)
}

/// Release a string returned by any function in this library.
#[no_mangle]
pub extern "C" fn sql_ast_simple_free(p: *mut c_char) {
    if !p.is_null() {
        unsafe { drop(CString::from_raw(p)) };
    }
}
