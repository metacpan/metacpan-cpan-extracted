[CHECK_PASSWORD]
-- Comments for SQL debug
-- Some::Program @ CHECK_PASSWORD
-- Check a user password
SELECT
 login,password
FROM
 {table}
WHERE
(
  login = '{login}',
 AND
  password = '{password}'
);
[/CHECK_PASSWORD]

[CHECK_PASSWORD]
 {table}:{login}:{password}
[/CHECK_PASSWORD]


[TEST1]
{table}:{login}:{password}
[/TEST1]

[TEST2]
                                 {table}:{login}:{password}
[/TEST2]













[CHECK_PASSWORD]
 {table}:{login}:{password}
[/CHECK_PASSWORD]












[TEST3]
{table}:{login}:{password}
[/TEST3]
[ TEST4            ]
{table}:{login}:{password}
[  /                     TEST4 ]





[TEST5]
{table}:{login}:{password}:{email}
[/TEST5]

