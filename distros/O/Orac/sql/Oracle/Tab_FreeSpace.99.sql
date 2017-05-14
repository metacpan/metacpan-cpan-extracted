/* Courtesy of Steve Deackoff, Bitwise Information Technology */
/* Written May 1998 */
/* Shows high water mark, used and unused blocks below high water mark */
--
declare
  v_segment_owner varchar2(30):=UPPER( ? );
  v_segment_name varchar2(30):=UPPER( ? );
  v_segment_type varchar2(30):='TABLE';
  v_total_blocks number;
  v_total_bytes number;
  v_unused_blocks number;
  v_unused_bytes number;
  v_last_used_extent_file_id number;
  v_last_used_extent_block_id number;
  v_last_used_block number;
  v_free_blks number;
begin
   dbms_output.enable(1000000);
   --
   dbms_output.put_line(  v_segment_type ||
                          ': ' ||
                          v_segment_owner || 
                          '.' || 
                          v_segment_name ||
                          chr(10)
                       );
   --
   --  procedure unused_space(segment_owner IN varchar2,
   --                         segment_name IN varchar2,
   --                         segment_type IN varchar2,
   --                         total_blocks OUT number,
   --                         total_bytes OUT number,
   --                         unused_blocks OUT number,
   --                         unused_bytes OUT number,
   --                         last_used_extent_file_id OUT number,
   --                         last_used_extent_block_id OUT number,
   --                         last_used_block OUT number
   --                        );
   --
   --  Returns information about unused space in an object (table, index,
   --  or cluster).
   --
   --  Input arguments:
   --   segment_owner: schema name of the segment to be analyzed
   --   segment_name:  object name of the segment to be analyzed
   --   segment_type:  type of the segment to be analyzed 
   --                  (TABLE, INDEX, or CLUSTER)
   --
   --  Output arguments:
   --   total_blocks:  total number of blocks in the segment
   --   total_bytes:   the same as above, expressed in bytes
   --   unused_blocks:  number of blocks which are not used
   --   unused_bytes:   the same as above, expressed in bytes
   --
   --   last_used_extent_file_id:  the file ID of the last extent which 
   --                              contains data
   --   last_used_extent_block_id: the block ID of the last extent 
   --                              which contains data
   --   last_used_block:           the last block within this extent 
   --                              which contains data
   --
   dbms_space.unused_space
              (v_segment_owner,
               v_segment_name,
               v_segment_type,
               v_total_blocks,
               v_total_bytes,
               v_unused_blocks,
               v_unused_bytes,
               v_last_used_extent_file_id,
               v_last_used_extent_block_id,
               v_last_used_block);
   --
   dbms_output.put_line(  'From dbms_space.unused_space'  );
   dbms_output.put_line(  '----------------------------'  );
   --
   dbms_output.put_line(  'Total number of BLOCKS(bytes) ' ||
                          'in the segment          = ' ||
                          v_total_blocks ||
                          '(' ||
                          v_total_bytes ||
                          ')'
                       );
   dbms_output.put_line(  'Number of BLOCKS(bytes) ' ||
                          'above high water mark         = ' ||
                          v_unused_blocks ||
                          '(' ||
                          v_unused_bytes ||
                          ')'
                       );
   dbms_output.put_line(  'The FILE ID of the last extent ' ||
                          'which contains data    = ' ||
                          v_last_used_extent_file_id
                       );
   dbms_output.put_line(  'The BLOCK ID of the last extent ' ||
                          'which contains data   = ' ||
                          v_last_used_extent_block_id
                       );
   dbms_output.put_line(  'The LAST BLOCK within this extent ' ||
                          'which contains data = ' ||
                          v_last_used_block || chr(10)
                       );
   --
   --  procedure free_blocks (segment_owner IN varchar2,
   --                         segment_name IN varchar2,
   --                         segment_type IN varchar2,
   --                         freelist_group_id IN number,
   --                         free_blks OUT number,
   --                         scan_limit IN number DEFAULT NULL
   --                         );
   --  Returns information about free blocks in an object 
   --  (table, index, or cluster).
   --
   --  Input arguments:
   --   segment_owner:         schema name of the segment to be analyzed
   --   segment_name:          name of the segment to be analyzed
   --   segment_type:          type of the segment to be analyzed 
   --                          (TABLE, INDEX, or CLUSTER)
   --   freelist_group_id:     freelist group (instance) whose free list 
   --                          size is to be computed
   --   scan_limit (optional): maximum number of free blocks to read
   --
   --  Output arguments:
   --   free_blks: count of free blocks for the specified group
   --
   dbms_space.free_blocks
              (  v_segment_owner,
                 v_segment_name,
                 v_segment_type,
                 0,
                 v_free_blks,
                 null
              );
   --
   dbms_output.put_line(  'From dbms_space.free_blocks'  );
   dbms_output.put_line(  '---------------------------' );
   --
   dbms_output.put_line(  'Number of FREE BLOCKS under high ' ||
                          'water mark           = ' ||
                          v_free_blks
                       );
   dbms_output.put_line(  'Number of USED BLOCKS under high ' ||
                          'water mark           = ' ||
                          to_char( v_total_blocks -
                                   v_unused_blocks -
                                   v_free_blks
                                 )
                       );
end;
