-- Requeue_busy_items
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] dest queue name (main queue)
-- # ARGV[1] timestamp
-- # ARGV[2] item
--
-- redis.log(redis.LOG_WARNING, "requeue_tail")
if #KEYS ~= 2 then error('requeue_failed_item requires 2 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local item  = assert(ARGV[2], 'item missing')

local n = redis.call('lrem', from, 1, item)

if n > 0 then
    local i = cjson.decode(item)

    if i.t_created == nil then
        i.t_created = i.t
    end
    i.t = ts

    local v = cjson.encode(i)
    redis.call('lpush', dest, v)
end
return n
