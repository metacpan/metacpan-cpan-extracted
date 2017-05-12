-- requeue_failed_gentle: requeue or requeue up to a given number of items
--   first call will rename the list to a temporary list
--   calls after that will work through the temporary list until is empty
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] dest queue name (main queue)
-- # KEYS[3] temp queue name (temporary queue)
-- # ARGV[1] timestamp
-- # ARGV[2] number of items to requeue. Value "0" means "all items"
-- # ARGV[3] delay before trying again after a fail
-- # ARGV[4] failed counter criterium
--
if #KEYS ~= 3 then error('requeue_failed_gentle.lua requires 3 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local temp  = assert(KEYS[3], 'temp queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local num   = assert(tonumber(ARGV[2]), 'number of items missing')
local delay = assert(tonumber(ARGV[3]), 'delay criterium missing')
local fc    = assert(tonumber(ARGV[4]), 'failed counter criterium missing')
local n_requeued = 0
local tmin  = 0

if redis.call('exists', temp) == 0 then
    if redis.call('exists', from) == 1 then
        redis.call('rename', from, temp)
    else
        return "0 0"
    end
end

local len = redis.call('llen', temp)

if len > 0 then
    if num == 0 or num > len then
        num = len
    end

    for i = 1, num do
        local item = redis.call('rpop', temp);
        if not item then break end

        local i = cjson.decode(item)
        tmin = ts - i.fc*delay

        if (fc == -1 or i.fc <= fc) and 
            (i.t <= tmin or (i.created ~= nil and i.created <=tmin)) then

            -- item should be requeued
            n_requeued = n_requeued + 1
            if i.t_created == nil then
                i.t_created = i.t
            end
            i.t = ts

            local v = cjson.encode(i)
            redis.call('lpush', dest, v)
        else
            -- put it back in failed queue
            redis.call('lpush', from, item)
        end
    end
end

-- return number of items handled and number of items removed from the failed
-- queue, space separated (as a string)
local todo = len - num
return todo .. ' ' .. n_requeued
