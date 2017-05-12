/* Thanks to Andy Campbell */
SELECT block_size
FROM ( SELECT bytes / blocks AS block_size
       FROM user_segments
       WHERE bytes IS NOT NULL
       AND blocks IS NOT NULL
       UNION
       SELECT bytes / blocks AS block_size
       FROM user_free_space
       WHERE bytes IS NOT NULL
       AND blocks IS NOT NULL
    )
WHERE rownum < 2
