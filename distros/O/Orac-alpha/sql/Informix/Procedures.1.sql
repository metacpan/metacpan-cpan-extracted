SELECT * FROM informix.sysprocedures --WHERE type = 'P'
{ -- to get the body, can we concat this?
select data as d from informix.sysprocbody
where datakey = 'T'
and procid = ?
}
