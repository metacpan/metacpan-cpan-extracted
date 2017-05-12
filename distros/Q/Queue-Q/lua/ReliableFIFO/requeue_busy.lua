-- requeue_busy (depending requeue limit items will be requeued or fail)
-- # KEYS[1] from queue name (busy queue)
-- # KEYS[2] dest queue name (main queue)
-- # KEYS[3] failed queue name (failed queue)
-- # ARGV[1] timestamp
-- # ARGV[2] item
-- # ARGV[3] requeue limit
-- # ARGV[4] place to requeue in dest-queue:
--      0: at producer side, 1: consumer side
--      Note: failed items will always go to the tail of the failed queue
-- # ARGV[5] OPTIONAL error message
--
--redis.log(redis.LOG_WARNING, "requeue_tail")
if #KEYS ~= 3 then error('requeue_busy requires 3 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'busy queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local failed= assert(KEYS[3], 'failed queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local item  = assert(ARGV[2], 'item missing')
local limit = assert(tonumber(ARGV[3]), 'requeue limit missing')
local place = tonumber(ARGV[4])
assert(place == 0 or place == 1, 'requeue place should be 0 or 1')

local n = redis.call('lrem', from, 1, item)

if n > 0 then
    local i= cjson.decode(item)
    if i.rc == nil then
        i.rc=1
    else
        i.rc=i.rc+1
    end

    if i.rc <= limit then
        -- only adjust timestamps in case of requeuing
        -- (not if busy item is place back in the front of the queue)
        if place == 0 then
            if i.t_created == nil then
                i.t_created = i.t
            end
            i.t = ts
        end

        local v=cjson.encode(i)
        if place == 0 then 
            redis.call('lpush', dest, v)
        else
            redis.call('rpush', dest, v)
        end
    else
        -- reset requeue counter and increase fail counter
        i.rc = nil
        if i.fc == nil then
            i.fc = 1
        else
            i.fc = i.fc + 1
        end
        if #ARGV == 5 then
            i.error = ARGV[5]
        else
            i.error = nil
        end
        local v=cjson.encode(i)
        redis.call('lpush', failed, v)
    end
end
return n
