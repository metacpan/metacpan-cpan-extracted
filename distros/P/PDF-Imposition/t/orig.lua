-- original code
function optimize_signature(pages,min,max)
   local minsignature = min or 40
   local maxsignature = max or 80
   local originalpages = pages

   -- here we want to be sure that the max and min are actual *4
   if (minsignature%4) ~= 0 then
      minsignature = minsignature + (4 - (minsignature % 4))
   end
   if (maxsignature%4) ~= 0 then
      maxsignature = maxsignature + (4 - (maxsignature % 4))
   end
   assert((minsignature % 4) == 0, "I suppose something is wrong, not a n*4")
   assert((maxsignature % 4) == 0, "I suppose something is wrong, not a n*4")

   --set needed pages to and and signature to 0
   local neededpages, signature = 0,0

   -- this means that we have to work with n*4, if not, add them to
   -- needed pages 
   local modulo = pages % 4
   if modulo==0 then
      signature=pages
   else
      neededpages = 4 - modulo
   end

   -- add the needed pages to pages
   pages = pages + neededpages
   
   if ((minsignature == 0) or (maxsignature == 0)) then 
      signature = pages -- the whole text
   else
      -- give a try with the signature
      signature = find_signature(pages, maxsignature)
      
      -- if the pages, are more than the max signature, find the right one
      if pages>maxsignature then
	 while signature<minsignature do
	    pages = pages + 4
	    neededpages = 4 + neededpages
	    signature = find_signature(pages, maxsignature)
	    --         global.texio.write_nl('term and log', "Trying signature of " .. signature)
	 end
      end
   end
   print(originalpages .. " " .. pages .. " " .. signature .. " " .. neededpages)
end

function find_signature(number, maxsignature)
   assert(number>3, "I can't find the signature for" .. number .. "pages")
   assert((number % 4) == 0, "I suppose something is wrong, not a n*4")
   local i = maxsignature
   while i>0 do
      -- global.texio.write_nl('term and log', "Trying " .. i  .. "for max of " .. maxsignature)
      if (number % i) == 0 then
	 return i
      end
      i = i - 4
   end
end

for pages = 1, 400, 1  do
    optimize_signature(pages, 39, 59)
end


