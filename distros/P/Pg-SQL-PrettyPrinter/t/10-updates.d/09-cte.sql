WITH w AS ( SELECT 1 AS s, 2 AS d ) UPDATE t SET a = w.d FROM w WHERE w.s = t.a
